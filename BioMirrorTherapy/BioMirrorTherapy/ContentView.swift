//
//  ContentView.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 30.03.2025.
//

import SwiftUI
import CoreData
import WatchConnectivity

struct ContentView: View {
    @ObservedObject var sessionViewModel = WatchSessionViewModel()
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("BioMirror Status")) {
                    HStack {
                        Text("Session")
                        Spacer()
                        Text(sessionViewModel.isSessionActive ? "Active" : "Inactive")
                            .foregroundColor(sessionViewModel.isSessionActive ? .green : .red)
                    }
                    
                    if sessionViewModel.isSessionActive {
                        HStack {
                            Text("Heart Rate")
                            Spacer()
                            Text(sessionViewModel.heartRateText)
                        }
                        
                        HStack {
                            Text("Duration")
                            Spacer()
                            Text(sessionViewModel.sessionDurationText)
                        }
                    }
                }
                
                Section {
                    Button(sessionViewModel.isSessionActive ? "Stop Session" : "Start Session") {
                        if sessionViewModel.isSessionActive {
                            sessionViewModel.stopSession()
                        } else {
                            sessionViewModel.startSession()
                        }
                    }
                    .foregroundColor(sessionViewModel.isSessionActive ? .red : .green)
                    
                    if !sessionViewModel.isStoreDataEmpty {
                        Button("Sync Data (\(sessionViewModel.storedDataCount))") {
                            sessionViewModel.syncData()
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("BioMirror")
        }
    }
}

