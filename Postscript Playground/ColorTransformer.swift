//
//  ColorTransformer.swift
//  SimplePsViewer
//
//  Created by Heinz-Jörg on 09.06.23.
//

import Cocoa


/// Subclass from `NSSecureUnarchiveFromDataTransformer`
@objc(ColorValueTransformer)
final class ColorValueTransformer: NSSecureUnarchiveFromDataTransformer {

    /// The name of the transformer. This is the name used to register the transformer using `ValueTransformer.setValueTrandformer(_"forName:)`.
    static let name = NSValueTransformerName(rawValue: String(describing: ColorValueTransformer.self))

    // Make sure `NSColor` is in the allowed class list.
    override static var allowedTopLevelClasses: [AnyClass] {
        return [NSColor.self]
    }

    /// Registers the transformer.
    public static func register() {
        let transformer = ColorValueTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
    
    /// We need Color-> Data and vice versa
    /// - Returns: true
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    /// Type of the transform
    /// - Returns: Class name
    override class func transformedValueClass() -> AnyClass {
        return NSColor.self
    }
    
    /// Transforms color to Data
    /// - Parameter value: NSColor as input
    /// - Returns: Data from the color
    /// This method is beeing called from xib. In case the preferences are not yet existing it could
    /// fail and return nil.
    override func transformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else {
            //fatalError("Wrong data type: value must be a Data object; received \(type(of: value))")
            return nil
        }
        return super.transformedValue(data)
    }
    
    /// Transforms Data to Color
    /// - Parameter value: Data as input
    /// - Returns: NScolor
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let color = value as? NSColor else {
            fatalError("Wrong data type: value must be a NSColor object; received \(type(of: value))")
            //return nil
        }
        return super.reverseTransformedValue(color)
    }

}



extension NSValueTransformerName {
    static let colorToDataTransformer = NSValueTransformerName(rawValue: "ColorValueTransformer")
}

