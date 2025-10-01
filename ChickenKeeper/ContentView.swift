// ChickenKeeperApp.swift
// Minimum deployment target: iOS 15.0
// Use SwiftUI
// Colors based on provided: Sunny Yellow #FFD93D, Coral Red #FF6B6B, Sky Blue #4A90E2, Grass Green #3DD598, Cream White #FFF9E6
// Icons: Use SF Symbols where possible, assume custom images for chickens (use placeholders)
// For weather: Use OpenWeatherMap for current weather only, no forecast
// Hardcode location to San Francisco for demo (lat=37.7749, lon=-122.4194)
// User can set API key in APIKeys struct
// Persistence with UserDefaults
// No initial data

import SwiftUI

// Hex color extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    static let sunnyYellow = Color(hex: "FFD93D")
    static let coralRed = Color(hex: "FF6B6B")
    static let skyBlue = Color(hex: "4A90E2")
    static let grassGreen = Color(hex: "3DD598")
    static let creamWhite = Color(hex: "FFF9E6")
}

// API Keys struct - user sets the key here
struct APIKeys {
    static var openWeatherMap: String = "2255aeb9e4f7e3edc0195b0627ba2ff6" // Set your OpenWeatherMap API key here
}

// Models
struct Reminder: Identifiable, Codable {
    var id = UUID()
    var title: String
    var type: ReminderType
    var date: Date
    var repeatOption: RepeatOption
    var notes: String
    var priority: Priority
    var isCompleted: Bool = false
}

enum ReminderType: String, CaseIterable, Codable {
    case feed = "Feed"
    case water = "Water"
    case clean = "Clean"
    case health = "Health"
    case vaccine = "Vaccine"
    
    var icon: String {
        switch self {
        case .feed: return "leaf"
        case .water: return "drop"
        case .clean: return "scissors"
        case .health: return "heart"
        case .vaccine: return "syringe"
        }
    }
    
    var color: Color {
        switch self {
        case .feed: return .sunnyYellow
        case .water: return .skyBlue
        case .clean: return .grassGreen
        case .health: return .coralRed
        case .vaccine: return .coralRed
        }
    }
}

enum RepeatOption: String, CaseIterable, Codable {
    case none = "None"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
}

enum Priority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var color: Color {
        switch self {
        case .low: return .grassGreen
        case .medium: return .skyBlue
        case .high: return .coralRed
        }
    }
}

struct Income: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var eggsSold: Int
    var pricePerDozen: Double
    var total: Double {
        (Double(eggsSold) / 12.0) * pricePerDozen
    }
}

struct Expense: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var amount: Double
    var category: ExpenseCategory
}

enum ExpenseCategory: String, CaseIterable, Codable {
    case feed = "Feed"
    case bedding = "Bedding"
    case healthcare = "Healthcare"
    case utilities = "Utilities"
    case other = "Other"
    
    var color: Color {
        switch self {
        case .feed: return .sunnyYellow
        case .bedding: return .coralRed
        case .healthcare: return .skyBlue
        case .utilities: return .grassGreen
        case .other: return .gray
        }
    }
}

// Weather model
struct WeatherData: Codable {
    let main: Main
    let weather: [Weather]
    let wind: Wind
    let visibility: Int
    
    struct Main: Codable {
        let temp: Double
        let humidity: Int
    }
    
    struct Weather: Codable {
        let description: String
        let icon: String
    }
    
    struct Wind: Codable {
        let speed: Double
    }
}

// AppData ViewModel
class AppData: ObservableObject {
    @Published var reminders: [Reminder] = [] {
        didSet { saveReminders() }
    }
    @Published var incomes: [Income] = [] {
        didSet { saveIncomes() }
    }
    @Published var expenses: [Expense] = [] {
        didSet { saveExpenses() }
    }
    
    init() {
        loadReminders()
        loadIncomes()
        loadExpenses()
    }
    
    private func saveReminders() {
        if let data = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(data, forKey: "reminders")
        }
    }
    
    private func loadReminders() {
        if let data = UserDefaults.standard.data(forKey: "reminders"),
           let loaded = try? JSONDecoder().decode([Reminder].self, from: data) {
            reminders = loaded
        }
    }
    
    private func saveIncomes() {
        if let data = try? JSONEncoder().encode(incomes) {
            UserDefaults.standard.set(data, forKey: "incomes")
        }
    }
    
    private func loadIncomes() {
        if let data = UserDefaults.standard.data(forKey: "incomes"),
           let loaded = try? JSONDecoder().decode([Income].self, from: data) {
            incomes = loaded
        }
    }
    
    private func saveExpenses() {
        if let data = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(data, forKey: "expenses")
        }
    }
    
    private func loadExpenses() {
        if let data = UserDefaults.standard.data(forKey: "expenses"),
           let loaded = try? JSONDecoder().decode([Expense].self, from: data) {
            expenses = loaded
        }
    }
    
    // Computed properties for stats
    func thisWeekProfit() -> Double {
        let thisWeekIncomes = incomes.filter { isThisWeek($0.date) }.reduce(0.0) { $0 + $1.total }
        let thisWeekExpenses = expenses.filter { isThisWeek($0.date) }.reduce(0.0) { $0 + $1.amount }
        return thisWeekIncomes - thisWeekExpenses
    }
    
    func thisWeekEggsLaid() -> Int {
        incomes.filter { isThisWeek($0.date) }.reduce(0) { $0 + $1.eggsSold }
    }
    
    func monthlyProfit() -> Double {
        let thisMonthIncomes = incomes.filter { isThisMonth($0.date) }.reduce(0.0) { $0 + $1.total }
        let thisMonthExpenses = expenses.filter { isThisMonth($0.date) }.reduce(0.0) { $0 + $1.amount }
        return thisMonthIncomes - thisMonthExpenses
    }
    
    func avgDozenPrice() -> Double {
        let thisMonthIncomes = incomes.filter { isThisMonth($0.date) }
        if thisMonthIncomes.isEmpty { return 0.0 }
        let totalEggs = thisMonthIncomes.reduce(0) { $0 + $1.eggsSold }
        let totalIncome = thisMonthIncomes.reduce(0.0) { $0 + $1.total }
        return totalIncome / (Double(totalEggs) / 12.0)
    }
    
    func monthlyPerformanceData() -> [(month: String, income: Double, expenses: Double, profit: Double)] {
        var data: [(month: String, income: Double, expenses: Double, profit: Double)] = []
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        
        for i in (0..<6).reversed() {
            if let monthDate = calendar.date(byAdding: .month, value: -i, to: Date()),
               let start = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)),
               let end = calendar.date(byAdding: .month, value: 1, to: start)?.addingTimeInterval(-1) {
                
                let monthIncomes = incomes.filter { $0.date >= start && $0.date <= end }.reduce(0.0) { $0 + $1.total }
                let monthExpenses = expenses.filter { $0.date >= start && $0.date <= end }.reduce(0.0) { $0 + $1.amount }
                let profit = monthIncomes - monthExpenses
                let monthName = formatter.string(from: start)
                data.append((month: monthName, income: monthIncomes, expenses: monthExpenses, profit: profit))
            }
        }
        return data
    }
    
    func expenseBreakdown() -> [(value: Double, color: Color, label: String)] {
        let grouped = Dictionary(grouping: expenses, by: { $0.category })
        return grouped.map { category, exps in
            let total = exps.reduce(0.0) { $0 + $1.amount }
            return (value: total, color: category.color, label: "\(category.rawValue) ($\(Int(total)))")
        }
    }
    
    private func isThisWeek(_ date: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    private func isThisMonth(_ date: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: Date(), toGranularity: .month)
    }
}

// Custom Bar Chart View
struct BarChart: View {
    let data: [(month: String, income: Double, expenses: Double, profit: Double)]
    let maxValue: Double
    
    init(data: [(month: String, income: Double, expenses: Double, profit: Double)]) {
        self.data = data
        self.maxValue = data.flatMap { [$0.income, $0.expenses, $0.profit] }.max() ?? 1.0
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(data, id: \.month) { item in
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.grassGreen)
                        .frame(height: CGFloat(item.income / maxValue) * 150)
                    Rectangle()
                        .fill(Color.coralRed)
                        .frame(height: CGFloat(item.expenses / maxValue) * 150)
                    Rectangle()
                        .fill(Color.sunnyYellow)
                        .frame(height: CGFloat(item.profit / maxValue) * 150)
                }
                .frame(width: 20)
            }
        }
        .frame(height: 150)
    }
}

// Custom Pie Chart View
struct PieChart: View {
    let slices: [(value: Double, color: Color)]
    
    var body: some View {
        GeometryReader { geometry in
            let total = slices.reduce(0) { $0 + $1.value }
            if total == 0 {
                Circle()
                    .fill(Color.gray.opacity(0.3))
            } else {
                var startAngle: Angle = .zero
                ForEach(0..<slices.count, id: \.self) { i in
                    let angle = Angle(degrees: 360 * (slices[i].value / total))
                    Path { path in
                        path.move(to: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2))
                        path.addArc(center: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2),
                                    radius: min(geometry.size.width, geometry.size.height) / 2,
                                    startAngle: startAngle,
                                    endAngle: startAngle + angle,
                                    clockwise: false)
                    }
                    .fill(slices[i].color)
                    let _ = { startAngle += angle }()
                }
            }
        }
        .frame(width: 150, height: 150)
    }
}

// Main App
@main
struct ChickenKeeperApp: App {
    @StateObject var appData = AppData()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appData)
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            RemindersView()
                .tabItem {
                    Label("CluckRe...", systemImage: "bell")
                }
            
            WeatherView()
                .tabItem {
                    Label("HenWeat...", systemImage: "cloud.sun")
                }
            
            ProfitView()
                .tabItem {
                    Label("EggProfit", systemImage: "dollarsign.circle")
                }
        }
        .accentColor(.sunnyYellow)
        .background(Color.creamWhite)
    }
}

// Dashboard View
struct DashboardView: View {
    @EnvironmentObject var appData: AppData
    @State private var showingCreateSheet = false
    @State private var toastMessage: String? = nil
    
    var todaysTasks: Int {
        appData.reminders.filter { Calendar.current.isDateInToday($0.date) }.count
    }
    
    var completedToday: Int {
        appData.reminders.filter { Calendar.current.isDateInToday($0.date) && $0.isCompleted }.count
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Good Morning!")
                                .font(.title.bold())
                            Text("Ready to care for your flock?")
                                .font(.subheadline)
                        }
                        Spacer()
                        Circle()
                            .fill(Color.sunnyYellow)
                            .frame(width: 50, height: 50)
                            .overlay(Text("🐔")) // Placeholder for chicken image
                    }
                    
                    Button("+ Add New Reminder") {
                        showingCreateSheet = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.sunnyYellow)
                    .cornerRadius(30)
                    .foregroundColor(.black)
                    
                    // Today's Tasks
                    HStack {
                        Circle()
                            .fill(Color.coralRed)
                            .frame(width: 40, height: 40)
                            .overlay(Text("📅"))
                        VStack(alignment: .leading) {
                            Text("Today's Tasks")
                            Text("\(completedToday) completed")
                                .font(.caption)
                        }
                        Spacer()
                        Text("\(todaysTasks)")
                            .bold()
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    
                    // Weather Alert
                    HStack {
                        Circle()
                            .fill(Color.skyBlue)
                            .frame(width: 40, height: 40)
                            .overlay(Text("📍"))
                        VStack(alignment: .leading) {
                            Text("Weather Alert")
                            Text("Perfect for free-range")
                                .font(.caption)
                        }
                        Spacer()
                        Text("Sunny")
                            .bold()
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    
                    // Profit Summary
                    HStack {
                        Circle()
                            .fill(Color.grassGreen)
                            .frame(width: 40, height: 40)
                            .overlay(Text("📈"))
                        VStack(alignment: .leading) {
                            Text("Profit Summary")
                            Text("This week")
                                .font(.caption)
                        }
                        Spacer()
                        Text("$\(Int(appData.thisWeekProfit()))")
                            .bold()
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    
                    Text("Recent Activity")
                        .font(.headline)
                    
                    if appData.reminders.isEmpty {
                        Text("No recent activity")
                            .italic()
                    } else {
                        VStack(spacing: 8) {
                            ForEach(appData.reminders.sorted(by: { $0.date > $1.date }).prefix(3)) { reminder in
                                TaskRow(title: reminder.title, time: DateFormatter.localizedString(from: reminder.date, dateStyle: .none, timeStyle: .short), status: reminder.isCompleted ? "completed" : "pending", color: reminder.isCompleted ? .grassGreen : .sunnyYellow)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.creamWhite)
            .navigationTitle("ChickenKeeper")
            .sheet(isPresented: $showingCreateSheet) {
                CreateReminderView { newReminder in
                    appData.reminders.insert(newReminder, at: 0)
                    toastMessage = "Reminder added 🐔"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        toastMessage = nil
                    }
                }
            }
            .overlay(
                toastMessage != nil ? Text(toastMessage!)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .transition(.opacity)
                    .animation(.easeInOut) : nil,
                alignment: .top
            )
        }
    }
}

struct TaskRow: View {
    let title: String
    let time: String
    let status: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(title)
            Spacer()
            Text(time)
                .font(.caption)
            Text(status)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .background(color)
                .cornerRadius(20)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
    }
}

// Reminders View
struct RemindersView: View {
    @EnvironmentObject var appData: AppData
    @State private var showingCreateSheet = false
    @State private var toastMessage: String? = nil
    
    var totalTasks: Int { appData.reminders.count }
    var completed: Int { appData.reminders.filter { $0.isCompleted }.count }
    var pending: Int { totalTasks - completed }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        StatBox(value: "\(totalTasks)", label: "Total Tasks")
                        StatBox(value: "\(completed)", label: "Completed")
                        StatBox(value: "\(pending)", label: "Pending")
                    }
                    
                    Button("+ Add New Reminder") {
                        showingCreateSheet = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.grassGreen)
                    .cornerRadius(30)
                    .foregroundColor(.black)
                    
                    ForEach($appData.reminders) { $reminder in
                        ReminderRow(reminder: $reminder)
                    }
                }
                .padding()
            }
            .background(Color.creamWhite)
            .navigationTitle("CluckRemind")
            .sheet(isPresented: $showingCreateSheet) {
                CreateReminderView { newReminder in
                    appData.reminders.insert(newReminder, at: 0)
                    toastMessage = "Reminder added 🐔"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        toastMessage = nil
                    }
                }
            }
            .overlay(
                toastMessage != nil ? Text(toastMessage!)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .transition(.opacity)
                    .animation(.easeInOut) : nil,
                alignment: .top
            )
        }
    }
}

struct StatBox: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title.bold())
            Text(label)
                .font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.creamWhite.opacity(0.5))
        .cornerRadius(10)
    }
}

struct ReminderRow: View {
    @Binding var reminder: Reminder
    
    var body: some View {
        HStack {
            Circle()
                .fill(reminder.type.color)
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: reminder.type.icon))
            VStack(alignment: .leading) {
                Text(reminder.title)
                Text(DateFormatter.localizedString(from: reminder.date, dateStyle: .short, timeStyle: .short) + " · " + reminder.repeatOption.rawValue)
                    .font(.caption)
            }
            Spacer()
            Text(reminder.priority.rawValue)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .background(reminder.priority.color)
                .cornerRadius(20)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .contentShape(Rectangle())
        .onTapGesture {
            reminder.isCompleted.toggle()
        }
    }
}

struct CreateReminderView: View {
    @State private var title: String = ""
    @State private var type: ReminderType = .feed
    @State private var date: Date = Date()
    @State private var repeatOption: RepeatOption = .none
    @State private var notes: String = ""
    @State private var priority: Priority = .medium
    let onSave: (Reminder) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var isValid: Bool {
        !title.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title e.g., Morning Feeding", text: $title)
                    Picker("Type", selection: $type) {
                        ForEach(ReminderType.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    DatePicker("Date & Time", selection: $date)
                    Picker("Repeat", selection: $repeatOption) {
                        ForEach(RepeatOption.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    TextField("Notes", text: $notes)
                }
            }
            .navigationTitle("Create Reminder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Reminder") {
                        let newReminder = Reminder(title: title, type: type, date: date, repeatOption: repeatOption, notes: notes, priority: priority)
                        onSave(newReminder)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// Weather View - Current weather only
struct WeatherView: View {
    @State private var weather: WeatherData?
    @State private var error: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                if let weather = weather {
                    VStack(spacing: 16) {
                        Text("\(Int(weather.main.temp))°F")
                            .font(.system(size: 60).bold())
                        Image(systemName: "sun.max")
                            .font(.largeTitle)
                        Text(weather.weather.first?.description.capitalized ?? "Sunny")
                            .font(.title)
                        
                        HStack {
                            VStack {
                                Text("\(weather.main.humidity)%")
                                Text("Humidity")
                            }
                            VStack {
                                Text("\(Int(weather.wind.speed)) mph")
                                Text("Wind")
                            }
                            VStack {
                                Text("\(weather.visibility / 1609) mi") // meters to miles approx
                                Text("Visibility")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Chicken Forecast
                        HStack {
                            Text("🐔")
                            Text("Perfect weather for free-range time! Your chickens will love the sunshine.")
                        }
                        .padding()
                        .background(Color.skyBlue.opacity(0.3))
                        .cornerRadius(20)
                        
                        Text("Weather Alerts")
                            .font(.headline)
                        
                        AlertRow(title: "Temperature rising - ensure fresh water is available", priority: "Medium", color: .sunnyYellow)
                        
                        Text("Weather Wisdom")
                            .font(.headline)
                        
                        Text("Chickens are most comfortable in temperatures between 55-75°F. In hot weather, provide extra shade and fresh water. In cold weather, ensure the coop is draft-free but well-ventilated.")
                            .padding()
                            .background(Color.grassGreen.opacity(0.3))
                            .cornerRadius(20)
                    }
                    .padding()
                } else if let error = error {
                    Text(error)
                } else {
                    Text("Loading weather...")
                }
            }
            .background(Color.creamWhite)
            .navigationTitle("HenWeather")
            .onAppear {
                fetchWeather()
            }
        }
    }
    
    func fetchWeather() {
        guard !APIKeys.openWeatherMap.isEmpty else {
            error = "Set OpenWeatherMap API key in APIKeys struct."
            return
        }
        
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=37.7749&lon=-122.4194&units=imperial&appid=\(APIKeys.openWeatherMap)"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, err in
            if let err = err {
                DispatchQueue.main.async { self.error = err.localizedDescription }
                return
            }
            guard let data = data else { return }
            do {
                let decoded = try JSONDecoder().decode(WeatherData.self, from: data)
                DispatchQueue.main.async { self.weather = decoded }
            } catch {
                DispatchQueue.main.async { self.error = error.localizedDescription }
            }
        }.resume()
    }
}

struct AlertRow: View {
    let title: String
    let priority: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
            Text(title)
            Spacer()
            Text(priority)
                .foregroundColor(.black)
                .padding(.horizontal, 8)
                .background(color)
                .cornerRadius(20)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
    }
}

// Profit View
struct ProfitView: View {
    @EnvironmentObject var appData: AppData
    @State private var showingAddIncome = false
    @State private var showingAddExpense = false
    @State private var toastMessage: String? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        StatCard(value: "$\(Int(appData.thisWeekProfit()))", label: "Profit", sublabel: "This Week", color: .grassGreen, icon: "arrow.up")
                        StatCard(value: "\(appData.thisWeekEggsLaid())", label: "Eggs Laid", sublabel: "This Week", color: .sunnyYellow, icon: "circle")
                    }
                    
                    Text("Quick Stats")
                        .font(.headline)
                    
                    HStack {
                        Text("$\(Int(appData.monthlyProfit()))")
                            .font(.title.bold())
                        Text("Monthly Profit")
                            .font(.caption)
                        Spacer()
                        Text("$\(String(format: "%.1f", appData.avgDozenPrice()))")
                            .font(.title.bold())
                        Text("Avg Dozen Price")
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    
                    Text("Monthly Performance")
                        .font(.headline)
                    
                    BarChart(data: appData.monthlyPerformanceData())
                    
                    HStack {
                        Circle().fill(Color.grassGreen).frame(width: 10)
                        Text("Income")
                        Circle().fill(Color.coralRed).frame(width: 10)
                        Text("Expenses")
                        Circle().fill(Color.sunnyYellow).frame(width: 10)
                        Text("Profit")
                    }
                    .font(.caption)
                    
                    Text("Expense Breakdown")
                        .font(.headline)
                    
                    PieChart(slices: appData.expenseBreakdown().map { ($0.value, $0.color) })
                    
                    VStack(alignment: .leading) {
                        ForEach(appData.expenseBreakdown(), id: \.label) { slice in
                            LegendItem(color: slice.color, label: slice.label)
                        }
                    }
                    
                    HStack {
                        Button("+ Add Income") {
                            showingAddIncome = true
                        }
                        .padding()
                        .background(Color.grassGreen)
                        .cornerRadius(30)
                        .foregroundColor(.black)
                        
                        Button("+ Add Expense") {
                            showingAddExpense = true
                        }
                        .padding()
                        .background(Color.coralRed)
                        .cornerRadius(30)
                        .foregroundColor(.black)
                    }
                    
                    HStack {
                        Image(systemName: "lightbulb")
                        VStack(alignment: .leading) {
                            Text("Profit Tip")
                            Text("Track daily egg counts and prices for better profit insights. A healthy hen lays about 5-6 eggs per week!")
                        }
                    }
                    .padding()
                    .background(Color.sunnyYellow.opacity(0.3))
                    .cornerRadius(20)
                }
                .padding()
            }
            .background(Color.creamWhite)
            .navigationTitle("EggProfit")
            .sheet(isPresented: $showingAddIncome) {
                AddIncomeView { newIncome in
                    appData.incomes.append(newIncome)
                    toastMessage = "Income added 💰"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        toastMessage = nil
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView { newExpense in
                    appData.expenses.append(newExpense)
                    toastMessage = "Expense added 📉"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        toastMessage = nil
                    }
                }
            }
            .overlay(
                toastMessage != nil ? Text(toastMessage!)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .transition(.opacity)
                    .animation(.easeInOut) : nil,
                alignment: .top
            )
        }
    }
}

struct AddIncomeView: View {
    @State private var eggsSold: String = ""
    @State private var pricePerDozen: String = ""
    @State private var date: Date = Date()
    let onSave: (Income) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var isValid: Bool {
        Int(eggsSold) != nil && Double(pricePerDozen) != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Eggs Sold", text: $eggsSold)
                        .keyboardType(.numberPad)
                    TextField("Price per Dozen", text: $pricePerDozen)
                        .keyboardType(.decimalPad)
                    DatePicker("Date", selection: $date)
                }
            }
            .navigationTitle("Add Income")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let eggs = Int(eggsSold), let price = Double(pricePerDozen) {
                            let newIncome = Income(date: date, eggsSold: eggs, pricePerDozen: price)
                            onSave(newIncome)
                            dismiss()
                        }
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}

struct AddExpenseView: View {
    @State private var amount: String = ""
    @State private var category: ExpenseCategory = .feed
    @State private var date: Date = Date()
    let onSave: (Expense) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var isValid: Bool {
        Double(amount) != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    DatePicker("Date", selection: $date)
                }
            }
            .navigationTitle("Add Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let amt = Double(amount) {
                            let newExpense = Expense(date: date, amount: amt, category: category)
                            onSave(newExpense)
                            dismiss()
                        }
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let sublabel: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack {
            Image(systemName: icon)
            Text(value)
                .font(.title.bold())
            Text(label)
            Text(sublabel)
                .font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color)
        .cornerRadius(20)
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppData())
}
