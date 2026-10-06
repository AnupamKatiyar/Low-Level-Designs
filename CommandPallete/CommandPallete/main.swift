//
//  main.swift
//  CommandPallete
//
//  Created by Anupam Katiyar on 27/08/26.
//

import Foundation

/*
Commands ──┐
Files ─────┤
Web ───────┤
AI/RAG ────┤
            ↓
       SearchCoordinator
            ↓
       Global Reranker
            ↓
          Top 3



             User
              |
              v
            SearchController
              |
            Debounce + Cancel
              |
              v
            SearchCoordinator
              |
            Parallel fan-out
               |
┌──────────────┼──────────────┐
↓              ↓              ↓
Commands     Files           Web
Provider    Provider       Provider
↓              ↓              ↓
└──────────────┼──────────────┘
               |
            Merge
              |
            Deduplicate
              |
            Authorization*
              |
            Global Ranking
              |
            Top 3
              |
              v
             UI
             
*/

// ============================================================
// MARK: - 1. Models
// ============================================================

enum ResultType {
    case command
    case file
    case application
    case web
}

struct SearchRequest {
    let query: String
    let userId: String
    let limit: Int
}

struct FileMetadata {
    let fileName: String
    let fileType: String
    let author: String?
    let tags: [String]
    let location: String
}

struct CommandAction {
    let id: String
    let title: String
}

struct SearchResult {
    let id: String
    let title: String
    let subtitle: String
    let type: ResultType

    // Which provider generated this result.
    let providerID: String

    // Provider-specific relevance.
    let providerScore: Double

    // Metadata used by global ranking.
    let selectionCount: Int
    let lastSelectedAt: Date?

    // Used after global ranking.
    var finalScore: Double = 0

    // Command-specific.
    let actions: [CommandAction]?

    // File-specific.
    let fileMetadata: FileMetadata?
}


// ============================================================
// MARK: - 2. Search Provider Protocol
// ============================================================

protocol SearchProvider {

    var id: String { get }

    func search(request: SearchRequest) async throws -> [SearchResult]
}


// ============================================================
// MARK: - 3. Command Provider
// ============================================================

final class CommandProvider: SearchProvider {

    let id = "command-provider"

    private let commands: [SearchResult] = [

        SearchResult(
            id: "create-file",
            title: "Create File",
            subtitle: "Create a new file",
            type: .command,
            providerID: "command-provider",
            providerScore: 0.95,
            selectionCount: 20,
            lastSelectedAt: Date().addingTimeInterval(-3600),
            finalScore: 0,
            actions: [
                CommandAction(
                    id: "create",
                    title: "Create"
                ),
                CommandAction(
                    id: "create-template",
                    title: "Create from Template"
                )
            ],
            fileMetadata: nil
        ),

        SearchResult(
            id: "create-project",
            title: "Create Project",
            subtitle: "Create a new project",
            type: .command,
            providerID: "command-provider",
            providerScore: 0.90,
            selectionCount: 10,
            lastSelectedAt: Date().addingTimeInterval(-7200),
            finalScore: 0,
            actions: [
                CommandAction(
                    id: "create",
                    title: "Create"
                )
            ],
            fileMetadata: nil
        ),

        SearchResult(
            id: "create-branch",
            title: "Create Branch",
            subtitle: "Create a Git branch",
            type: .command,
            providerID: "command-provider",
            providerScore: 0.80,
            selectionCount: 5,
            lastSelectedAt: Date().addingTimeInterval(-86400),
            finalScore: 0,
            actions: [
                CommandAction(
                    id: "create",
                    title: "Create"
                )
            ],
            fileMetadata: nil
        ),

        // Seed command.
        SearchResult(
            id: "open-settings",
            title: "Open Settings",
            subtitle: "Open system settings",
            type: .command,
            providerID: "command-provider",
            providerScore: 0.70,
            selectionCount: 0,
            lastSelectedAt: nil,
            finalScore: 0,
            actions: [
                CommandAction(
                    id: "open",
                    title: "Open"
                )
            ],
            fileMetadata: nil
        )
    ]

    func search(
        request: SearchRequest
    ) async throws -> [SearchResult] {

        let query = request.query.lowercased()

        return commands.filter {
            $0.title.lowercased().contains(query)
        }
    }
}


// ============================================================
// MARK: - 4. File Provider
// ============================================================

final class FileProvider: SearchProvider {

    let id = "file-provider"

    private let files: [SearchResult] = [

        SearchResult(
            id: "credit-report",
            title: "CreditReport.pdf",
            subtitle: "~/Documents",
            type: .file,
            providerID: "file-provider",
            providerScore: 0.92,
            selectionCount: 15,
            lastSelectedAt: Date().addingTimeInterval(-5000),
            finalScore: 0,
            actions: nil,
            fileMetadata: FileMetadata(
                fileName: "CreditReport.pdf",
                fileType: "PDF",
                author: "Anupam",
                tags: ["finance", "report"],
                location: "~/Documents"
            )
        ),

        SearchResult(
            id: "create-project-doc",
            title: "CreateProject.docx",
            subtitle: "~/Documents",
            type: .file,
            providerID: "file-provider",
            providerScore: 0.75,
            selectionCount: 3,
            lastSelectedAt: Date().addingTimeInterval(-50000),
            finalScore: 0,
            actions: nil,
            fileMetadata: FileMetadata(
                fileName: "CreateProject.docx",
                fileType: "DOCX",
                author: "Anupam",
                tags: ["project", "development"],
                location: "~/Documents"
            )
        )
    ]

    func search(
        request: SearchRequest
    ) async throws -> [SearchResult] {

        let query = request.query.lowercased()

        return files.filter { result in

            guard let metadata = result.fileMetadata else {
                return false
            }

            // Search filename.
            if metadata.fileName.lowercased().contains(query) {
                return true
            }

            // Search file type.
            if metadata.fileType.lowercased().contains(query) {
                return true
            }

            // Search author.
            if metadata.author?
                .lowercased()
                .contains(query) == true {
                return true
            }

            // Search tags.
            if metadata.tags.contains(where: {
                $0.lowercased().contains(query)
            }) {
                return true
            }

            return false
        }
    }
}


// ============================================================
// MARK: - 5. Application Provider
// ============================================================

final class ApplicationProvider: SearchProvider {

    let id = "application-provider"

    private let applications: [SearchResult] = [

        SearchResult(
            id: "chrome",
            title: "Google Chrome",
            subtitle: "Application",
            type: .application,
            providerID: "application-provider",
            providerScore: 0.90,
            selectionCount: 100,
            lastSelectedAt: Date().addingTimeInterval(-300),
            finalScore: 0,
            actions: nil,
            fileMetadata: nil
        ),

        SearchResult(
            id: "creative-cloud",
            title: "Creative Cloud",
            subtitle: "Application",
            type: .application,
            providerID: "application-provider",
            providerScore: 0.85,
            selectionCount: 50,
            lastSelectedAt: Date().addingTimeInterval(-3600),
            finalScore: 0,
            actions: nil,
            fileMetadata: nil
        )
    ]

    func search(
        request: SearchRequest
    ) async throws -> [SearchResult] {

        let query = request.query.lowercased()

        return applications.filter {
            $0.title.lowercased().contains(query)
        }
    }
}


// ============================================================
// MARK: - 6. Web Provider
// ============================================================

final class WebProvider: SearchProvider {

    let id = "web-provider"

    func search(
        request: SearchRequest
    ) async throws -> [SearchResult] {

        // Simulate network latency.
        try await Task.sleep(for: .milliseconds(100))

        let query = request.query.lowercased()

        let results = [
            SearchResult(
                id: "web-create-react",
                title: "Create React App",
                subtitle: "Web result",
                type: .web,
                providerID: id,
                providerScore: 0.95,
                selectionCount: 0,
                lastSelectedAt: nil,
                finalScore: 0,
                actions: nil,
                fileMetadata: nil
            ),

            SearchResult(
                id: "web-create-project",
                title: "How to create a project",
                subtitle: "Web result",
                type: .web,
                providerID: id,
                providerScore: 0.80,
                selectionCount: 0,
                lastSelectedAt: nil,
                finalScore: 0,
                actions: nil,
                fileMetadata: nil
            )
        ]

        return results.filter {
            $0.title.lowercased().contains(query)
        }
    }
}

// ============================================================
// MARK: - 7. AI Provider
// ============================================================

final class AIProvider: SearchProvider {
    let id = "ai-provider"
    
    func search(
        request: SearchRequest
    ) async throws -> [SearchResult] {
        // Query embedding
        // Vector search
        // RAG retrieval
        // Return candidates
        
        return []//Dummpy Result
    }
}

// ============================================================
// MARK: - 8. Search History
// ============================================================

struct UsageInfo {
    var selectionCount: Int
    var lastSelectedAt: Date?
}

final class SearchHistory {

    private var usage: [String: UsageInfo] = [:]

    func recordSelection(resultID: String) {

        var info = usage[resultID] ?? UsageInfo(
            selectionCount: 0,
            lastSelectedAt: nil
        )

        info.selectionCount += 1
        info.lastSelectedAt = Date()

        usage[resultID] = info
    }

    func getUsage(
        resultID: String
    ) -> UsageInfo {

        return usage[resultID] ?? UsageInfo(
            selectionCount: 0,
            lastSelectedAt: nil
        )
    }
}


// ============================================================
// MARK: - 9. Ranking Strategy Protocol
// ============================================================

protocol RankingStrategy {

    func rank(
        results: [SearchResult],
        request: SearchRequest
    ) -> [SearchResult]
}


// ============================================================
// MARK: - 10. Frequency + Recency Ranker
// ============================================================

final class FrequencyRecencyRanker: RankingStrategy {

    private let frequencyWeight = 0.30
    private let recencyWeight = 0.20
    private let relevanceWeight = 0.50

    func rank(
        results: [SearchResult],
        request: SearchRequest
    ) -> [SearchResult] {

        let now = Date()

        var rankedResults = results.map { result -> SearchResult in

            let frequencyScore =
                log(1 + Double(result.selectionCount))

            var recencyScore = 0.0

            if let lastSelected = result.lastSelectedAt {

                let age =
                    now.timeIntervalSince(lastSelected)

                // 24-hour decay.
                recencyScore =
                    exp(-age / 86400.0)
            }

            let relevanceScore =
                result.providerScore

            let finalScore =
                relevanceWeight * relevanceScore +
                frequencyWeight * frequencyScore +
                recencyWeight * recencyScore

            var updatedResult = result
            updatedResult.finalScore = finalScore

            return updatedResult
        }

        rankedResults.sort {
            $0.finalScore > $1.finalScore
        }

        return rankedResults
    }
}


// ============================================================
// MARK: - 11. Deduplicator
// ============================================================

final class SearchDeduplicator {

    func deduplicate(
        results: [SearchResult]
    ) -> [SearchResult] {

        var map: [String: SearchResult] = [:]

        for result in results {

            if let existing = map[result.id] {

                // Keep result having better provider score.
                if result.providerScore >
                    existing.providerScore {

                    map[result.id] = result
                }

            } else {
                map[result.id] = result
            }
        }

        return Array(map.values)
    }
}


// ============================================================
// MARK: - 12. Search Coordinator
// ============================================================

final class SearchCoordinator {

    private let providers: [SearchProvider]

    private let ranker: RankingStrategy

    private let history: SearchHistory

    private let deduplicator: SearchDeduplicator

    init(
        providers: [SearchProvider],
        ranker: RankingStrategy,
        history: SearchHistory,
        deduplicator: SearchDeduplicator
    ) {
        self.providers = providers
        self.ranker = ranker
        self.history = history
        self.deduplicator = deduplicator
    }

    // --------------------------------------------------------
    // Search
    // --------------------------------------------------------

    func search(
        query: String,
        userId: String,
        limit: Int
    ) async -> [SearchResult] {

        guard !query.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty else {
            return []
        }

        let request = SearchRequest(
            query: query,
            userId: userId,
            limit: limit
        )

        var allResults: [SearchResult] = []

        /*
         Fan-out.

         All providers execute concurrently.
        */

        await withTaskGroup(
            of: [SearchResult].self
        ) { group in

            for provider in providers {

                group.addTask {

                    do {

                        return try await provider.search(
                            request: request
                        )

                    } catch {

                        /*
                         Fault tolerance.

                         If Web provider fails, local
                         providers can still return results.
                        */

                        print(
                            "Provider \(provider.id) failed: \(error)"
                        )

                        return []
                    }
                }
            }

            for await results in group {
                allResults.append(contentsOf: results)
            }
        }

        // ----------------------------------------------------
        // Merge
        // ----------------------------------------------------

        let uniqueResults =
            deduplicator.deduplicate(
                results: allResults
            )

        // ----------------------------------------------------
        // Update ranking information from user history
        // ----------------------------------------------------

        let resultsWithHistory =
            uniqueResults.map { result -> SearchResult in

                let usage =
                    history.getUsage(
                        resultID: result.id
                    )

                var updated = result

                /*
                 Runtime user history should override
                 static provider metadata.
                */

                updated = SearchResult(
                    id: updated.id,
                    title: updated.title,
                    subtitle: updated.subtitle,
                    type: updated.type,
                    providerID: updated.providerID,
                    providerScore: updated.providerScore,
                    selectionCount: usage.selectionCount
                        > 0
                        ? usage.selectionCount
                        : updated.selectionCount,
                    lastSelectedAt: usage.lastSelectedAt
                        ?? updated.lastSelectedAt,
                    finalScore: 0,
                    actions: updated.actions,
                    fileMetadata: updated.fileMetadata
                )

                return updated
            }

        // ----------------------------------------------------
        // Global ranking
        // ----------------------------------------------------

        return ranker.rank(
            results: resultsWithHistory,
            request: request
        )
    }

    // --------------------------------------------------------
    // User selected a result
    // --------------------------------------------------------

    func select(
        resultID: String
    ) {

        history.recordSelection(
            resultID: resultID
        )
    }
}


// ============================================================
// MARK: - 11. Debounced Search Controller
// ============================================================

/*
 This represents the UI-facing layer.

 Important:
 Debouncing should normally happen on the client/UI side,
 before sending unnecessary search requests.
*/

final class SearchController {

    private let searchCoordinator: SearchCoordinator

    private var pendingTask: Task<Void, Never>?

    init(searchCoordinator: SearchCoordinator) {
        self.searchCoordinator = searchCoordinator
    }

    func onQueryChanged(query: String, userId: String) {

        // Cancel previous query.
        pendingTask?.cancel()

        pendingTask = Task {

            do {

                /*
                 Wait for user to stop typing.

                 Example:

                 c
                 cr
                 cre

                 Only "cre" gets searched.
                */

                try await Task.sleep(
                    for: .milliseconds(100)
                )

                guard !Task.isCancelled else {
                    return
                }

                let results =
                    await searchCoordinator.search(
                        query: query,
                        userId: userId,
                        limit: 3
                    )

                guard !Task.isCancelled else {
                    return
                }

                showResults(results)

            } catch {

                // Task was cancelled.
            }
        }
    }

    private func showResults(
        _ results: [SearchResult]
    ) {

        print("\n========== RESULTS ==========")

        for result in results {

            print(
                """
                \(result.title)
                Provider : \(result.providerID)
                Type     : \(result.type)
                Score    : \(String(
                    format: "%.3f",
                    result.finalScore
                ))
                """
            )

            if let metadata = result.fileMetadata {

                print(
                    "File: \(metadata.fileName)"
                )

                print(
                    "Type: \(metadata.fileType)"
                )

                print(
                    "Tags: \(metadata.tags.joined(separator: ", "))"
                )
            }

            if let actions = result.actions {

                print(
                    "Actions: \(actions.map { $0.title }.joined(separator: ", "))"
                )
            }

            print("-----------------------------")
        }
    }
}


// ============================================================
// MARK: - 12. Application / Composition Root
// ============================================================

//@main
struct Application {

    static func main() async {

        // ----------------------------------------------------
        // Create providers
        // ----------------------------------------------------

        let providers: [SearchProvider] = [

            CommandProvider(),

            FileProvider(),

            ApplicationProvider(),

            WebProvider(),
            
            AIProvider()
        ]

        // ----------------------------------------------------
        // Create dependencies
        // ----------------------------------------------------

        let history = SearchHistory()

        let ranker = FrequencyRecencyRanker()

        let deduplicator = SearchDeduplicator()

        // ----------------------------------------------------
        // Create coordinator
        // ----------------------------------------------------

        let coordinator =
            SearchCoordinator(
                providers: providers,
                ranker: ranker,
                history: history,
                deduplicator: deduplicator
            )

        // ----------------------------------------------------
        // Create UI controller
        // ----------------------------------------------------

        let controller = SearchController(searchCoordinator: coordinator)

        
        // ----------------------------------------------------
        // Simulate typing
        // ----------------------------------------------------

        controller.onQueryChanged(
            query: "c",
            userId: "user-1"
        )

        controller.onQueryChanged(
            query: "cr",
            userId: "user-1"
        )

        controller.onQueryChanged(
            query: "cre",
            userId: "user-1"
        )

        // Give async search some time.
        try? await Task.sleep(
            for: .milliseconds(500)
        )

        // ----------------------------------------------------
        // Simulate user selecting a command.
        // ----------------------------------------------------

        coordinator.select(
            resultID: "create-file"
        )

        print("\nCommand selected.")
    }
}



