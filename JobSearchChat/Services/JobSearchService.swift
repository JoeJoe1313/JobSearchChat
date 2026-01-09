import Foundation
import SwiftSoup

struct JobListing: Hashable {
    let title: String
    let company: String
    let datePosted: String
    let link: String
}

enum JobSearchError: Error, LocalizedError {
    case invalidDate(String)
    case invalidURL(String)

    var errorDescription: String? {
        switch self {
        case .invalidDate(let value):
            return "Invalid date format: \(value)"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        }
    }
}

struct JobSearchService {
    static let maxPages = 15

    static func search(category: String, date: String) async throws -> String {
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedCategory.isEmpty {
            return "Missing job category. Please provide a category."
        }

        let targetDate = parseDate(date)
        let jobs = try await fetchJobs(category: trimmedCategory, targetDate: targetDate)

        if jobs.isEmpty {
            return "No jobs found for category '\(trimmedCategory)' on \(formatDate(targetDate)) on dev.bg"
        }

        var result = "Found \(jobs.count) jobs in '\(trimmedCategory)' category for \(formatDate(targetDate)):\n\n"
        for (index, job) in jobs.enumerated() {
            result += "\(index + 1). \(job.title)\n"
            result += "   Company: \(job.company)\n"
            result += "   Posted: \(job.datePosted)\n"
            if !job.link.isEmpty {
                result += "   Link: \(job.link)\n"
            }
            result += "\n"
        }

        return result
    }

    static func fetchJobs(category: String, targetDate: Date) async throws -> [JobListing] {
        let categoryParam = categoryParameter(for: category)
        guard !categoryParam.isEmpty else { return [] }

        var listings: [JobListing] = []

        for page in 1...maxPages {
            let urlString = "https://dev.bg/company/jobs/\(categoryParam)?_paged=\(page)"
            guard let url = URL(string: urlString) else {
                throw JobSearchError.invalidURL(urlString)
            }

            var request = URLRequest(url: url)
            request.setValue(
                "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
                forHTTPHeaderField: "User-Agent"
            )

            let (data, _) = try await URLSession.shared.data(for: request)
            guard let html = String(data: data, encoding: .utf8) else { continue }

            let document = try SwiftSoup.parse(html)
            let jobElements = try document.select("div[class^=job-list-item]")
            if jobElements.array().isEmpty {
                break
            }

            for element in jobElements.array() {
                let title = try element.select("h6[class*=job-title]").text()
                let company = try element.select("[class*=company], [class*=employer]").text()
                let dateText = try element.select("span.date").text()
                let link = try element.select("a").first()?.attr("href") ?? ""

                guard let postedDate = parseBgDate(dateText) else { continue }
                if !Calendar.current.isDate(postedDate, inSameDayAs: targetDate) {
                    continue
                }

                let normalizedLink = link.hasPrefix("http") ? link : "https://dev.bg\(link)"

                listings.append(
                    JobListing(
                        title: title.isEmpty ? "Title not found" : title,
                        company: company.isEmpty ? "Company not specified" : company,
                        datePosted: dateText,
                        link: normalizedLink
                    )
                )
            }
        }

        return listings
    }

    static func categoryParameter(for category: String) -> String {
        let mapping: [String: String] = [
            "data science": "data-science",
            "machine learning": "data-science",
            "data": "data-science",
            "backend development": "back-end-development",
            "python development": "python",
        ]

        let key = category.lowercased()
        if let mapped = mapping[key] {
            return mapped
        }

        return key.replacingOccurrences(of: " ", with: "-")
    }

    static func parseBgDate(_ dateText: String) -> Date? {
        let months: [String: Int] = [
            "\u{044f}\u{043d}.": 1,
            "\u{0444}\u{0435}\u{0432}\u{0440}\u{0443}\u{0430}\u{0440}\u{0438}": 2,
            "\u{043c}\u{0430}\u{0440}\u{0442}": 3,
            "\u{0430}\u{043f}\u{0440}\u{0438}\u{043b}": 4,
            "\u{043c}\u{0430}\u{0439}": 5,
            "\u{044e}\u{043d}\u{0438}": 6,
            "\u{044e}\u{043b}\u{0438}": 7,
            "\u{0430}\u{0432}\u{0433}\u{0443}\u{0441}\u{0442}": 8,
            "\u{0441}\u{0435}\u{043f}\u{0442}\u{0435}\u{043c}\u{0432}\u{0440}\u{0438}": 9,
            "\u{043e}\u{043a}\u{0442}\u{043e}\u{043c}\u{0432}\u{0440}\u{0438}": 10,
            "\u{043d}\u{043e}\u{0435}\u{043c}\u{0432}\u{0440}\u{0438}": 11,
            "\u{0434}\u{0435}\u{043a}.": 12,
        ]

        let parts = dateText.lowercased().split(separator: " ")
        guard parts.count == 2,
              let day = Int(parts[0]),
              let month = months[String(parts[1])] else {
            return nil
        }

        var components = DateComponents()
        components.year = Calendar.current.component(.year, from: Date())
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)
    }

    static func parseDate(_ input: String) -> Date {
        let normalized = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalized == "today" {
            return Date()
        }
        if normalized == "yesterday" {
            return Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: normalized) {
            return date
        }

        return Date()
    }

    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
