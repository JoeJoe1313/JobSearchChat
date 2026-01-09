import Foundation
import MLXLMCommon

struct JobSearchInput: Codable {
    let category: String
    let date: String?
}

struct JobSearchOutput: Codable {
    let toolResult: String
}

enum JobSearchTool {
    static let tool = Tool<JobSearchInput, JobSearchOutput>(
        name: "get_todays_jobs",
        description: "Get jobs posted today or on a given date in a specific category from dev.bg",
        parameters: [
            .required(
                "category",
                type: .string,
                description: "The job category (e.g., 'Data Science', 'Software Development', 'DevOps')."
            ),
            .optional(
                "date",
                type: .string,
                description: "The date to search (e.g., 'today', 'yesterday', '2024-06-15'). Defaults to 'today'."
            ),
        ]
    ) { input in
        let date = input.date?.isEmpty == false ? input.date! : "today"
        let result = try await JobSearchService.search(category: input.category, date: date)
        return JobSearchOutput(toolResult: result)
    }
}
