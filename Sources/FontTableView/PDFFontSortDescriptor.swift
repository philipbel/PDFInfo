import Foundation
import PDFKitExt


final nonisolated class PDFFontSortDescriptor: NSSortDescriptor {
    private enum CodingKeys: String {
        case systemAvailableFonts
    }
    private let systemAvailableFonts: Set<String>

    override class var supportsSecureCoding: Bool {
        true
    }

    init(key: String, ascending: Bool, systemAvailableFonts: Set<String> = []) {
        self.systemAvailableFonts = systemAvailableFonts
        super.init(key: key, ascending: ascending, selector: nil)
    }

    required init?(coder: NSCoder) {
        guard let systemAvailableFonts = coder.decodeObject(
            of: [NSSet.self, NSString.self], forKey: CodingKeys.systemAvailableFonts.rawValue) as? Set<String> else {
            return nil
        }
        self.systemAvailableFonts = systemAvailableFonts
        super.init(coder: coder)
    }

    override func encode(with coder: NSCoder) {
        coder.encode(systemAvailableFonts, forKey: CodingKeys.systemAvailableFonts.rawValue)
        super.encode(with: coder)
    }

    override func copy(with zone: NSZone? = nil) -> Any {
        return self
    }

    override func compare(_ object1: Any, to object2: Any) -> ComparisonResult {
        guard let lhs = object1 as? any PDFFont else {
            assertionFailure("object1 is not PDFFont: \(type(of: object1))")
            return .orderedSame
        }
        guard let rhs = object2 as? any PDFFont else {
            assertionFailure("object2 is not PDFFont: \(type(of: object2))")
            return .orderedSame
        }

        let result: ComparisonResult
        switch key {
        case FontTableViewColumn.nameColumn.key:
            result = lhs.displayName.localizedStandardCompare(rhs.displayName)
        case FontTableViewColumn.typeColumn.key:
            result = FontUtil.typeString(for: lhs)
                .localizedStandardCompare(FontUtil.typeString(for: rhs))
        case FontTableViewColumn.embeddedColumn.key:
            result = Self.compareBools(lhs.isEmbedded, rhs.isEmbedded)
        case FontTableViewColumn.subsetColumn.key:
            result = Self.compareBools(lhs.isSubset, rhs.isSubset)
        case FontTableViewColumn.installedColumn.key:
            result = Self.compareBools(systemAvailableFonts.contains(lhs.id), systemAvailableFonts.contains(rhs.id))
        default:
            assertionFailure("Invalid key '\(String(describing: key))'")
            result = .orderedSame
        }

        if !ascending {
            if result == .orderedAscending {
                return .orderedDescending
            } else if result == .orderedDescending {
                return .orderedAscending
            }
        }
        return result
    }

    override var reversedSortDescriptor: Any {
        guard let key else {
            return super.reversedSortDescriptor
        }
        return PDFFontSortDescriptor(key: key, ascending: !ascending, systemAvailableFonts: systemAvailableFonts)
    }

    private static func compareBools(_ a: Bool, _ b: Bool) -> ComparisonResult {
        return switch (a ? 1 : 0) - (b ? 1 : 0) {
        case -1:
                .orderedAscending
        case 1:
                .orderedDescending
        default:
                .orderedSame
        }
    }
}
