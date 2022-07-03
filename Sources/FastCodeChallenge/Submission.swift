import Foundation

public struct Submission<T: Encodable>: Encodable {
    public let answer: T
    public let hardware: String?
    
    public init(answer: T, hardware: String?) {
        self.answer = answer
        self.hardware = hardware
    }
    
    public init(answer: T) {
        self.answer = answer
        
        let info = ProcessInfo.processInfo
        
        let lowPowerMode: String?
        
        if #available(macOS 12.0, *) {
            lowPowerMode = info.isLowPowerModeEnabled ? "low power mode" : nil
        } else {
            lowPowerMode = nil
        }
        
        let MB: UInt64 = 1024*1024
        
        let infoList = [
            "\(Process.sysctl(property: "machdep.cpu.brand_string") ?? "Unknown CPU")",
            "\(info.activeProcessorCount) cores",
            "\(info.physicalMemory/MB) MB",
            lowPowerMode
        ]
        self.hardware = infoList.compactMap { $0 }
            .reduce("", { $0 + $1 + ", " })
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .punctuationCharacters)
    }
}

extension Process {
    static func sysctl(property: String) -> String? {
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", "sysctl -n " + property]
        task.launch()
        return String(data: pipe.fileHandleForReading.availableData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
