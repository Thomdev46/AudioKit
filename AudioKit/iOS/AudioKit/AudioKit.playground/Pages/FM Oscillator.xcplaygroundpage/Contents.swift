//: [TOC](Table%20Of%20Contents) | [Previous](@previous) | [Next](@next)
//:
//: ---
//:
//: ## FM Oscillator
//: ### Generating audio
import XCPlayground
import AudioKit

let audiokit = AKManager.sharedInstance

//: Try changing the table type to triangle or another AKTableType
//: or changing the number of points to a smaller number (has to be a power of 2)
var fm = AKFMOscillator(table: AKTable(.Sine, size: 4096))
audiokit.audioOutput = fm
audiokit.start()

let updater = AKPlaygroundLoop(frequency: 5) {
    fm.baseFrequency.randomize(220, 880)
    fm.carrierMultiplier.randomize(0, 4)
    fm.modulationIndex.randomize(0, 5)
    fm.modulatingMultiplier.randomize(0, 0.3)
    fm.amplitude.randomize(0, 0.3)
}

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true
//: [TOC](Table%20Of%20Contents) | [Previous](@previous) | [Next](@next)
