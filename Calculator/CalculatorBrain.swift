//
//  File.swift
//  Calculator
//
//  Created by Iuliia Omelchuk on 20.12.2021.
//

import Foundation


struct CalculatorBrain {
    
    // MARK: - Private
    
    private var sequence = [Component]()
    
    private enum Component {
        case operand(Double)
        case operation(String)
        case variable(String)
    }
    
    private enum Operation {
        case constant(Double)
        case unaryOperation((Double) -> Double, (String) -> String)
        case binaryOperation ((Double,Double) -> Double, (String,String) -> String)
        case equals
    }
    
    private enum ErrorOperation {
        case unaryOperation((Double) -> String?)
        case binaryOperation((Double, Double) -> String?)
    }
    
    private var operations: Dictionary<String,Operation> = [
        "⍴": Operation.constant(Double.pi),
        "√": Operation.unaryOperation(sqrt, { "√(" + $0 + ")" }),
        "+/-": Operation.unaryOperation({ -$0 }, { "(-" + $0 + ")" }),
        "×": Operation.binaryOperation(*, { "(" + $0 + ")" + "×" + $1 }),
        "÷": Operation.binaryOperation(/, { "(" + $0 + ")" + "÷" + $1 }),
        "+": Operation.binaryOperation(+, { $0 + "+" + $1 }),
        "−": Operation.binaryOperation(-, { $0 + "−" + $1 }),
        "%": Operation.unaryOperation({$0 / 100.00},{$0 + "%"}),
        
        "x²" : Operation.unaryOperation({ pow($0, 2) }, { "(" + $0 + ")²" }),
        "xʸ" : Operation.binaryOperation(pow, { $0 + "^" + $1 }),
        "x!" : Operation.unaryOperation(factorial, { "(" + $0 + ")!" }),
        "log" : Operation.unaryOperation(log10, { "log(" + $0 + ")" }),
        
        "=": Operation.equals,
    ]
    
    private let errorOperations: Dictionary<String,ErrorOperation> = [
        "√": ErrorOperation.unaryOperation({ 0.0 > $0 ? "SQRT of negative Number" : nil }),
        "÷": ErrorOperation.binaryOperation({ 0 == $1 ? "Division by Zero" : nil }),
        "log" : ErrorOperation.unaryOperation({ 0 > $0 ? "LOG of negative Number" : nil }),
        "x!" : ErrorOperation.unaryOperation({ 0 > $0 ? "Factorial of negative Number" : nil })
    ]
    
    // MARK: - Variables
    
    var description: String? {
        return evaluate().description
    }
    
    var resultIsPending: Bool {
        return evaluate().ResultIsPending
    }
    
    var result: Double? {
        return evaluate().result
    }
    
    // MARK: - Methods
    
    mutating func setOperand(_ operand: Double) {
        sequence.append(Component.operand(operand))
    }
    
    mutating func setOperandVariableName(variable named: String) {
        sequence.append(Component.variable(named))
    }
    
    mutating func performOperation (_ symbol: String) {
        sequence.append(Component.operation(symbol))
    }
    
    mutating func undo(){
        if !sequence.isEmpty {
            sequence.removeLast()
        }
    }
    
    func evaluate(using variables: Dictionary<String,Double>? = nil)
    -> (result: Double?, ResultIsPending: Bool, description: String, error: String?) {
        
        var accumulator: (Double,String)?
        var error: String?
        var pendingBinaryOperation: PendingBinaryOperation?
        
        var resultIsPending: Bool {
            pendingBinaryOperation != nil
        }
        
        var result: Double? {
            if accumulator != nil {
                return accumulator!.0
            }
            else {
                return nil
            }
        }
        
        var description: String? {
            if resultIsPending {
                return pendingBinaryOperation!.description(pendingBinaryOperation!.firstOperand.1, accumulator?.1 ?? "")
            } else {
                return accumulator?.1
            }
        }
        
        struct PendingBinaryOperation {
            let function: (Double, Double) -> Double
            let description: (String, String) -> String
            let firstOperand: (Double, String)
            let symbol: String
            
            func perform( with secondOperand: (Double, String)) -> (Double,String) {
                return (function (firstOperand.0, secondOperand.0), description(firstOperand.1, secondOperand.1))
            }
        }
        
        func performPendingBinaryOperation() {
            if pendingBinaryOperation != nil && accumulator != nil {
                if let errorOperation = errorOperations[pendingBinaryOperation!.symbol],
                   case .binaryOperation(let errorFunction) = errorOperation {
                    error = errorFunction(pendingBinaryOperation!.firstOperand.0, accumulator!.0)
                }
                accumulator = pendingBinaryOperation!.perform(with: accumulator!)
                pendingBinaryOperation = nil
            }
        }
        
        for component in sequence {
            switch component {
            case .operand(let value):
                accumulator = (value, formatDouble(double: value))
            case .operation(let symbol):
                if let operetion = operations[symbol] {
                    switch operetion {
                    case .constant (let value):
                        accumulator = (value, symbol)
                    case .unaryOperation( let function, let description):
                        if accumulator != nil {
                            if let errorOperation = errorOperations[symbol],
                               case .unaryOperation(let errorFunction) = errorOperation {
                                error = errorFunction(accumulator!.0)
                            }
                            accumulator = (function(accumulator!.0), description(accumulator!.1))
                        }
                    case .binaryOperation(let function, let description):
                        performPendingBinaryOperation()
                        if accumulator != nil {
                            pendingBinaryOperation = PendingBinaryOperation(function: function, description: description, firstOperand: accumulator!, symbol: symbol)
                            accumulator = nil
                        }
                    case .equals:
                        performPendingBinaryOperation()
                    }
                }
            case .variable(let symbol):
                if let value = variables?[symbol] {
                    accumulator = (value, symbol)
                } else {
                    accumulator = (0, symbol)
                }
            }
            
        }
        
        return (result, pendingBinaryOperation != nil, description ?? "", error)
    }

    func formatDouble(double: Double) -> String {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = ","
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 6
        
        return formatter.string(from: NSNumber(value: double))!
    }

    
}


func factorial(_ value: Double) -> Double {
    if (value <= 1.0) {
        return 1.0
    }
    return value * factorial(value - 1.0)
}



