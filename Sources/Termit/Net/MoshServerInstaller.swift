import Foundation

enum MoshInstallStrategy: String, CaseIterable, Identifiable {
    case sshOnly
    case packageManager
    case portableBinary
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sshOnly: return "Use SSH for this session"
        case .packageManager: return "Install via package manager (sudo)"
        case .portableBinary: return "Drop portable binary (no sudo)"
        }
    }

    var subtitle: String {
        switch self {
        case .sshOnly:
            return "Works now. Session ends on network change."
        case .packageManager:
            return "Permanent install. Needs sudo. Affects the whole system."
        case .portableBinary:
            return "Lands in your home directory only. No sudo. Reversible."
        }
    }
}

actor MoshServerInstaller {
    enum DistroKind: String {
        case debian, ubuntu, fedora, centos, rocky, almalinux, opensuse, alpine, arch, macos, unknown
    }

    struct Probe {
        let hasMoshServer: Bool
        let portablePath: String?
        let arch: String
        let kernel: String
        let distro: DistroKind
        let distroVersion: String?
        let userHasSudo: Bool
    }

    private let ssh: SSHClient
    init(ssh: SSHClient) { self.ssh = ssh }

    func probe() async throws -> Probe {
        let detection = try await ssh.executeCommand("""
            command -v mosh-server || true
            test -x "$HOME/.local/bin/mosh-server" && echo "PORTABLE:$HOME/.local/bin/mosh-server" || true
            uname -m
            uname -s
            (cat /etc/os-release 2>/dev/null || sw_vers 2>/dev/null) | head -10
            sudo -n true 2>&1 && echo SUDO:YES || echo SUDO:NO
            """)
        let lines = detection.split(separator: "\n").map(String.init)
        var hasMoshServer = false
        var portable: String?
        var arch = "x86_64"
        var kernel = "Linux"
        var distro: DistroKind = .unknown
        var distroVersion: String?
        var sudo = false

        for line in lines {
            if line.contains("/mosh-server") {
                if line.hasPrefix("PORTABLE:") {
                    portable = String(line.dropFirst("PORTABLE:".count))
                } else {
                    hasMoshServer = true
                }
            }
            if line == "x86_64" || line == "aarch64" || line == "arm64" || line == "armv7l" {
                arch = line
            }
            if line == "Linux" || line == "Darwin" || line == "FreeBSD" {
                kernel = line
            }
            if line.hasPrefix("ID=") {
                let id = String(line.dropFirst(3)).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                distro = DistroKind(rawValue: id) ?? .unknown
            }
            if line.hasPrefix("VERSION_ID=") {
                distroVersion = String(line.dropFirst("VERSION_ID=".count))
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            }
            if line.hasPrefix("ProductName:") {
                distro = .macos
            }
            if line == "SUDO:YES" { sudo = true }
        }

        if kernel == "Darwin" { distro = .macos }

        return Probe(
            hasMoshServer: hasMoshServer,
            portablePath: portable,
            arch: arch,
            kernel: kernel,
            distro: distro,
            distroVersion: distroVersion,
            userHasSudo: sudo
        )
    }

    func install(strategy: MoshInstallStrategy, probe: Probe) async throws {
        switch strategy {
        case .sshOnly:
            return
        case .packageManager:
            try await installViaPackageManager(probe: probe)
        case .portableBinary:
            try await dropPortableBinary(probe: probe)
        }
    }

    private func installViaPackageManager(probe: Probe) async throws {
        let cmd: String
        switch probe.distro {
        case .debian, .ubuntu:
            cmd = "sudo -n DEBIAN_FRONTEND=noninteractive apt-get update -qq && sudo -n apt-get install -y -qq mosh"
        case .fedora, .centos, .rocky, .almalinux:
            cmd = "sudo -n dnf install -y -q mosh || sudo -n yum install -y -q mosh"
        case .opensuse:
            cmd = "sudo -n zypper install -y mosh"
        case .alpine:
            cmd = "sudo -n apk add --no-cache mosh"
        case .arch:
            cmd = "sudo -n pacman -S --noconfirm mosh"
        case .macos:
            cmd = "brew install mosh"
        case .unknown:
            throw MoshInstallError.unknownDistro
        }
        let output = try await ssh.executeCommand(cmd)
        if !output.lowercased().contains("error") {
            let verify = try await ssh.executeCommand("command -v mosh-server")
            guard verify.contains("/mosh-server") else { throw MoshInstallError.verifyFailed(verify) }
        }
    }

    private func dropPortableBinary(probe: Probe) async throws {
        let arch = mapArch(probe.arch, kernel: probe.kernel)
        guard let url = Bundle.main.url(forResource: "mosh-server-\(arch)", withExtension: nil, subdirectory: "MoshServer") else {
            throw MoshInstallError.unsupportedArchitecture(arch)
        }
        let data = try Data(contentsOf: url)
        let b64 = data.base64EncodedString()
        let remotePath = "$HOME/.local/bin/mosh-server"
        let cmd = """
            set -e
            mkdir -p "$HOME/.local/bin"
            printf '%s' '\(b64)' | base64 -d > "\(remotePath)"
            chmod 755 "\(remotePath)"
            "\(remotePath)" --version | head -1
            """
        let verify = try await ssh.executeCommand(cmd)
        guard verify.contains("mosh-server") else { throw MoshInstallError.verifyFailed(verify) }
    }

    private func mapArch(_ arch: String, kernel: String) -> String {
        let os = kernel.lowercased() == "darwin" ? "darwin" : "linux"
        let canonical: String
        switch arch {
        case "x86_64", "amd64": canonical = "x86_64"
        case "aarch64", "arm64": canonical = "aarch64"
        case "armv7l": canonical = "armv7l"
        default: canonical = arch
        }
        return "\(os)-\(canonical)"
    }
}

enum MoshInstallError: Error {
    case unknownDistro
    case unsupportedArchitecture(String)
    case verifyFailed(String)
}
