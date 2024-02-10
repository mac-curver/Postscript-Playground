//
//  Utilities.swift
//  Postscript Playground
//
//  Created by LegoEsprit on 15.12.23.
//

import Foundation


/// Helper method to fill in not yet coded blocks. Can be used everywhere avoiding compile errors,
/// but crashes when being executed.
/// - Parameter message: Message telling what needs to be done to complete the code.
/// - Returns: The type the compiler was complaining for.
func undefined<T>(_ message: String = "") -> T {
	fatalError("Undefined: \(message)")
}


/// Add double toSeconds to Duration from Swift.misc.
@available(macOS 13.0, *)
extension Duration {
	
	/// Returns the Duration components as s: Double
	var toSeconds: Double {
		let v = components
		return Double(v.seconds) + Double(v.attoseconds) * 1e-18
	}
	
}


@available(macOS, unavailable)
class BenchTimer {
	let startTime: DispatchTime = DispatchTime.now()
	var endTime: DispatchTime?
		
	func stop() -> Double {
		endTime = DispatchTime.now()
		return duration
	}
	
	var duration: Double {
		let endTime = DispatchTime.now().uptimeNanoseconds
		return 10E-9 * Double(endTime - startTime.uptimeNanoseconds)
	}
}




/// Profiling time record with total, maximum and number of calls information.
@available(macOS 13.0, *)
struct ProfileTime {
	/// Total elapsed time in this method. Will be counted up for any call by init or add().
	fileprivate var sum: Duration
	/// Maximum elapsed time for this method.
	/// Will be updated by add().
	fileprivate var	max: Duration
	/// Number of calls of this method.
	/// Will be updated by add()
	fileprivate var count: UInt64
	
	/// Default initializer - Resets all fields.
	/// ```
	/// Sets all fields to "0"
	/// ```
	init() {
		self.sum = .seconds(0)
		self.max = .seconds(0)
		self.count = 0
	}
	
	
	/// Initailizer to be used for the first call.
	/// - Parameter duration: Must be filled with the elapsed time for the the very first call.
	/// ```
	/// Called from Profile.add() when no time profile yet available. Normally
	/// no need to call this constructor explicitely!
	/// ```
	init(duration: Duration) {
		self.sum = duration
		self.max = duration
		self.count = 1
	}
	
	/// Adds timining information on subsequent calls.
	/// - Parameter time: Elapsed time for the current method call.
	/// ```
	/// Called from Profile.add() to update the elapsed time information.
	/// ```
	mutating func add(_ time: Duration) {
		sum += time
		if max < time {
			max = time
		}
		count += 1
	}
	
	/// Average elapsed time inside this method.
	/// ```
	/// Just calculated by sum over number of calls.
	/// ```
	var avg: Double {
		return 0 != count ? sum.toSeconds/Double(count) : 0.0
	}
}



/// Implements struct to do simple profiling by method
@available(macOS 13.0, *)
struct Profile {
	
	/// Dictionary with names and profile times.
	/// ```
	/// Storage for the profiling data. Stores profiling information for
	/// each name of method
	/// ```
	static var profiles: [String: ProfileTime] = [:]
	
	/// Used to measure the timining
	/// ```
	/// Seams to be a reliable clock to measure the exact profiling times.
	/// ```
	let clock = ContinuousClock()
	
	
	/// Measurement function to profile a block
	/// - Parameters:
	///   - className optional: Use className here as we don't have something like #classname
	///   - functionName optional: Automatically filled in by func tion name, but might be overwritten
	///   - work: Block to be measured, is allowed to throw and to return a value
	/// - Returns: Result of the original method used in the block
	/// ```
	/// // Can be used with any return type and even propagates throws!
	/// // 1. Example to measure elapsed time in a function body:
	/// func testBody(test: String) {
	///         profile.measure(className: self.className, {
	///         // ... time consuming calculation
	/// 		})
	/// )
	/// // Here the functionName is being filled in automaticaly.
	///
	/// // 2. Other example to evaluate test2:
	/// func testCall(param: Int) -> Int {
	///     // ... time consuming calculation
	///  	return 1
	/// }
	///
	///	a = profile.measure(className: self.className
	///						, functionName: "testCall"
	///						, {self.testCall(param: Int)}
	///		)
	///	```
	func measure<T>(className: String = "Global"
					, functionName: String = #function
					, _ work: () throws -> T
	) rethrows -> T? {
		var result: T?
		let duration = try clock.measure {
			result = try work()
		}
		add(name: className.lastComponent + "." + functionName, duration: duration)
		return result
	}

	
	/// Calculate classname (not used)
	/// - Parameter of: class or struct name or instance
	/// - Returns: Classname as type String
	/// ```
	/// Even it looks simple it was tricky to find.
	/// ```

	fileprivate func className(of: Any) -> String {
		return String(describing: type(of: of))
	}

	
	/// Adds profile to dictionary
	/// - Parameters:
	///   - name: Name as combination of class and function
	///   - duration: Measured duration
	/// ```
	/// This is the real worker method adding a profile to the dictionary.
	///	If called for the first time it constructs a new profile, after
	///	being updated for each call.
	/// ```
	private func add(name: String, duration: Duration) {
		if let _ = Profile.profiles[name] {
			/// add Profile if name is already in dictionary
			Profile.profiles[name]?.add(duration)
		}
		else {
			/// create a new dictionary entry with the measured value
			Profile.profiles[name] = ProfileTime(duration: duration)
		}
	}
	
	/// Print a table of the results into console window.
	/// ```
	/// Formatting is essential here. The table width is fixed to 80
	/// characters. Therefore some method names might be cut.
	/// ```
	func print() {
		//          12345678901234567890123456789012345678901234567890
		Swift.print("""
					name                                             \
					count      average          max
					"""
		)
		Swift.print(String(repeating: "=", count: 80))
		for (name, profileTime) in Profile.profiles.sorted(
			by: {
				left, right in
				left.key < right.key
			}
		) {
			let fill = name + String(repeating: " ", count: 45)
			let abr = String(
						fill[...fill.index(
							fill.startIndex, offsetBy: 45
						)]
			          )
			Swift.print(
				String(format: "%@%8d %12.6f %12.6f"
							   , abr
							   , profileTime.count
							   , profileTime.avg
							   , profileTime.max.toSeconds
				)
			)
		}
		Swift.print(String(repeating: "-", count: 80))

	}
}

@available(macOS 13.0, *)
let profile = Profile()



