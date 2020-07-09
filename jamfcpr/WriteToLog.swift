//
//  WriteToLog.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 2/21/19.
//  Copyright © 2019 jamf. All rights reserved.
//

import Foundation
class WriteToLog {
    
    var logFileW: FileHandle? = FileHandle(forUpdatingAtPath: "")
    var writeToLogQ = DispatchQueue(label: "com.jamf.writeToLogQ", qos: DispatchQoS.utility)
    let fm          = FileManager()
    
    // func logCleanup - start
    func logCleanup() {
        if History.didRun {
            var logArray: [String] = []
            var logCount: Int = 0
            do {
                let logFiles = try fm.contentsOfDirectory(atPath: History.logPath!)
                
                for logFile in logFiles {
                    let filePath: String = History.logPath! + logFile
                    logArray.append(filePath)
                }
                logArray.sort()
                logCount = logArray.count
                // remove old history files
                if logCount-1 >= History.maxFiles {
                    for i in (0..<logCount-History.maxFiles) {
                        WriteToLog().message(stringOfText: "Deleting log file: " + logArray[i] + "\n")
                        
                        do {
                            try fm.removeItem(atPath: logArray[i])
                        }
                        catch let error as NSError {
                            WriteToLog().message(stringOfText: "Error deleting log file:\n    " + logArray[i] + "\n    \(error)\n")
                        }
                    }
                }
            } catch {
                print("no history")
            }
        } else {
            // delete empty log file
            do {
                try fm.removeItem(atPath: History.logPath! + History.logFile)
            }
            catch let error as NSError {
                WriteToLog().message(stringOfText: "Error deleting log file:    \n" + History.logPath! + History.logFile + "\n    \(error)\n")
            }
        }
    }
    // func logCleanup - end

    func message(stringOfText: String) {
        writeToLogQ.sync {
            let logString = "\(self.getCurrentTime()) \(stringOfText)\n"
            
            self.logFileW = FileHandle(forUpdatingAtPath: (History.logPath! + History.logFile))
            
            self.logFileW?.seekToEndOfFile()
            let historyText = (logString as NSString).data(using: String.Encoding.utf8.rawValue)
            self.logFileW?.write(historyText!)
//            self.logFileW?.closeFile()
        }
    }
    
    func getCurrentTime() -> String {
        let current = Date()
        let localCalendar = Calendar.current
        let dateObjects: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        let dateTime = localCalendar.dateComponents(dateObjects, from: current)
        let currentMonth  = leadingZero(value: dateTime.month!)
        let currentDay    = leadingZero(value: dateTime.day!)
        let currentHour   = leadingZero(value: dateTime.hour!)
        let currentMinute = leadingZero(value: dateTime.minute!)
        let currentSecond = leadingZero(value: dateTime.second!)
        let stringDate = "\(dateTime.year!)\(currentMonth)\(currentDay)_\(currentHour)\(currentMinute)\(currentSecond)"
        return stringDate
    }
    
    // add leading zero to single digit integers
    func leadingZero(value: Int) -> String {
        var formattedValue = ""
        if value < 10 {
            formattedValue = "0\(value)"
        } else {
            formattedValue = "\(value)"
        }
        return formattedValue
    }

}
