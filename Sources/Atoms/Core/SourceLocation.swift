internal struct SourceLocation: Equatable {
    let fileID: String
    let line: UInt

    init(fileID: String = #fileID, line: UInt = #line) {
        self.fileID = fileID
        self.line = line
    }
}
