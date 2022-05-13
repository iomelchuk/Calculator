//
//  ViewController.swift
//  Calculator
//
//  Created by Iuliia Omelchuk on 06.12.2021.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var descriptionDisplay: UILabel!
    @IBOutlet weak var memoryDisplay: UILabel?
    
    var userIsTyping = false
    
    private var brain = CalculatorBrain()
    private var variables = Dictionary<String,Double>()
   
    // MARK: - Result
    
    var displayValue : Double {
        get {
            return Double(display.text!)!
        }
        set {
            display!.text = brain.formatDouble(double: newValue)
        }
    }
    
    private func displayResult() {
        let evaluated = brain.evaluate(using: variables)
        
        if let error = evaluated.error {
            display.text = error
        } else if let result = evaluated.result {
            displayValue = result
        }
        
        if userIsTyping {
            descriptionDisplay.text! +=  evaluated.description
        }
        else {
            if !evaluated.description.isEmpty  {
                // if resultIspending add "..."
                descriptionDisplay.text = evaluated.description + (evaluated.ResultIsPending ? "…" : "")
            }
            else {
                descriptionDisplay.text = " "
            }
        }
    }
    
    // MARK: - Digits and Operations
    
    @IBAction func touchDigit(_ sender: UIButton) {
        let digit = sender.currentTitle!
        let textCurrentlyInDisplay = display.text!
        
        if userIsTyping {
            // Corner case 00, user typing multiple leading zere 000 -> 0
            if (textCurrentlyInDisplay == "0" && digit == "0") || textCurrentlyInDisplay == "0" {
                display.text = digit
            }
            else {
                display.text = textCurrentlyInDisplay + digit
            }
        }
        else {
            if !brain.resultIsPending {
                descriptionDisplay.text = " "
            }
            
            display.text = digit
            userIsTyping = true
        }
    }
    
    @IBAction func touchDot(_ sender: UIButton) {
        let textCurrentlyInDisplay = display.text!
        
        if userIsTyping  {
            // Corner case ..., user typing multiple dots 5... -> 5.
            if textCurrentlyInDisplay.contains(".") {
                display.text = textCurrentlyInDisplay
            } else {
                display.text = textCurrentlyInDisplay + "."
            }
        } else {
            if !brain.resultIsPending {
                descriptionDisplay.text = " "
            }
            // Corner case ".", user typing dot after lunching, reset or performed operation
            display.text = "0."
        }
        userIsTyping = true
    }
    
    @IBAction func performOperation(_ sender: UIButton) {
        if userIsTyping {
            brain.setOperand(displayValue)
            userIsTyping = false
        }
        
        if let mathSymbol = sender.currentTitle {
            brain.performOperation(mathSymbol)
        }
        
        displayResult()
    }
    
    // MARK: - History
    
    @IBAction func resetCalculator(_ sender: UIButton) {
        brain = CalculatorBrain()
        displayValue = 0
        descriptionDisplay.text = "Description"
        memoryDisplay?.text = nil
        userIsTyping = false
        variables = [:]
    }
    

    @IBAction func backspace(_ sender: UIButton) {
        if userIsTyping, var text = display.text {
            text.remove(at: text.index(before: text.endIndex))
            if text.isEmpty || text == "0" {
                text = "0"
                userIsTyping = false
            }
            display.text = text
        } else {
            brain.undo()
            displayValue = 0 // test
            displayResult()
        }
    }
    
    // MARK: - Memory
    
    @IBAction func setVariableToMemory(_ sender: UIButton) {
        variables["M"] = displayValue
        
        guard let memoryValue = variables["M"] else {
            return
        }

        brain.setOperand(memoryValue)
        userIsTyping = false
        displayResult()
        memoryDisplay?.text = "M: " + brain.formatDouble(double: memoryValue)

    }
    
    @IBAction func getVariableFromMemory(_ sender: UIButton) {
        if let memoryValue = variables["M"] {
            brain.setOperand(memoryValue)
        } else {
            brain.setOperand(0.0)
        }
      
        userIsTyping = false
        displayResult()
    }
 
}


