import SwiftUI
import AVFoundation

struct IntervalEntry: Codable, Identifiable {
    var id = UUID() // Unique identifier for each interval
    var type: String
    var duration: Double
}

struct ContentView: View {
    @State private var selectedDate = Date()
    @AppStorage("intervalsByDate") private var savedIntervalsData: Data = Data()
    @State private var intervalsByDate: [String: [IntervalEntry]] = [:]
    @State private var isRunning = false
    @State private var currentIntervalIndex: Int = 0
    @State private var remainingTime: Double = 0
    @State private var timer: Timer?
    @State private var player: AVAudioPlayer?
    @State private var selectedType: String = "Run"
    @State private var inputDuration: String = "60"

    var body: some View {
        VStack {
            Text("Select Date")
                .font(.headline)
                .frame(maxWidth: 320)
                .padding()

            DatePicker("Workout Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                .onChange(of: selectedDate) { _ in
                    loadIntervalsForSelectedDate()
                }

            Text("Add Interval")
                .font(.headline)
                .padding()

            HStack {
                Picker("Type", selection: $selectedType) {
                    Text("Run").tag("Run")
                    Text("Walk").tag("Walk")
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 140)

                TextField("Seconds", text: $inputDuration)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .frame(width: 80)
            }
            .padding()

            Button("Add Interval") {
                addInterval()
            }
            .padding()
            .frame(width: 200, height: 50)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)

            List {
                ForEach(intervalsByDate[formattedDate(selectedDate), default: []]) { interval in
                    HStack {
                        Text("\(interval.type) - \(Int(interval.duration)) sec")
                        Spacer()
                        Button("❌") {
                            deleteInterval(id: interval.id)
                        }
                    }
                }
            }
            .frame(height: 160)

            HStack(spacing: 20)
                 {
                Button(action: startTimer) {
                    Text(isRunning ? "Pause" : "Start")
                        .padding()
                        .frame(width: 110, height: 50)
                        .background(isRunning ? Color.orange : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button(action: resetTimer) {
                    Text("Reset")
                        .padding()
                        .frame(width: 90)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
                 .padding(.top, 20)
                 .padding(.bottom, 200)
        }
        .padding()
        .onAppear(perform: loadSavedIntervals)
        .onTapGesture {
            hideKeyboard() // Call function to dismiss keyboard
        }
    }

    func addInterval() {
        if let duration = Double(inputDuration), duration > 0 {
            let dateKey = formattedDate(selectedDate)
            let newInterval = IntervalEntry(type: selectedType, duration: duration)
            intervalsByDate[dateKey, default: []].append(newInterval)
            saveIntervals()
        }
    }

    func deleteInterval(id: UUID) {
        let dateKey = formattedDate(selectedDate)
        intervalsByDate[dateKey]?.removeAll { $0.id == id }
        saveIntervals()
    }

    func loadIntervalsForSelectedDate() {
        let dateKey = formattedDate(selectedDate)
        if intervalsByDate[dateKey] == nil {
            intervalsByDate[dateKey] = []
        }
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    func saveIntervals() {
        do {
            let data = try JSONEncoder().encode(intervalsByDate)
            savedIntervalsData = data
        } catch {
            print("Error saving intervals: \(error)")
        }
    }

    func loadSavedIntervals() {
        do {
            if let loadedData = try? JSONDecoder().decode([String: [IntervalEntry]].self, from: savedIntervalsData) {
                intervalsByDate = loadedData
            }
        } catch {
            print("Error loading saved intervals: \(error)")
        }
    }

    func startTimer() {
        let dateKey = formattedDate(selectedDate)
        guard let intervals = intervalsByDate[dateKey], !intervals.isEmpty else { return }

        if isRunning {
            timer?.invalidate()
            isRunning = false
        } else {
            isRunning = true
            currentIntervalIndex = 0
            remainingTime = intervals[currentIntervalIndex].duration
            runTimer()
        }
    }

    func runTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                switchInterval()
            }
        }
    }

    func switchInterval() {
        playSound()
        let dateKey = formattedDate(selectedDate)
        guard let intervals = intervalsByDate[dateKey] else { return }

        if currentIntervalIndex < intervals.count - 1 {
            currentIntervalIndex += 1
            remainingTime = intervals[currentIntervalIndex].duration
        } else {
            timer?.invalidate()
            isRunning = false
        }
    }

    func resetTimer() {
        timer?.invalidate()
        isRunning = false
        let dateKey = formattedDate(selectedDate)
        intervalsByDate[dateKey]?.removeAll()
        saveIntervals()
        currentIntervalIndex = 0
        remainingTime = 0
    }

    func playSound() {
        guard let url = Bundle.main.url(forResource: "beep", withExtension: "mp3") else { return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch {
            print("Error playing sound")
        }
    }
}
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct IntervalTimerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}


