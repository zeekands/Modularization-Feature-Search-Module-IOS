//
//  SearchViewModel.swift
//  FeatureSearch
//
//  Created by zeekands on 04/07/25.
//


import Foundation
import SharedDomain
import SharedUI
import SwiftUI
import Combine

@MainActor
public final class SearchViewModel: ObservableObject {
    @Published public var searchQuery: String = "" // User's search query
    @Published public var movieResults: [MovieEntity] = [] // Movie search results
    @Published public var tvShowResults: [TVShowEntity] = [] // TV Show search results
    @Published public var isLoading: Bool = false // For loading indicator
    @Published public var errorMessage: String? = nil // For displaying errors

    private var searchTask: Task<Void, Never>? // For debouncing search input

    // Use Case dependencies
    private let searchMoviesUseCase: SearchMoviesUseCaseProtocol
    private let searchTVShowsUseCase: SearchTVShowsUseCaseProtocol
    private let getMovieDetailUseCase: GetMovieDetailUseCaseProtocol // To fetch detail if navigating
    private let getTVShowDetailUseCase: GetTVShowDetailUseCaseProtocol // To fetch detail if navigating
    private let toggleFavoriteUseCase: ToggleFavoriteUseCaseProtocol // To toggle favorite status

    // Navigation dependency
    private let appNavigator: AppNavigatorProtocol

    private var cancellables = Set<AnyCancellable>() // To store Combine subscriptions

    public init(
        searchMoviesUseCase: SearchMoviesUseCaseProtocol,
        searchTVShowsUseCase: SearchTVShowsUseCaseProtocol,
        getMovieDetailUseCase: GetMovieDetailUseCaseProtocol,
        getTVShowDetailUseCase: GetTVShowDetailUseCaseProtocol,
        toggleFavoriteUseCase: ToggleFavoriteUseCaseProtocol,
        appNavigator: AppNavigatorProtocol
    ) {
        self.searchMoviesUseCase = searchMoviesUseCase
        self.searchTVShowsUseCase = searchTVShowsUseCase
        self.getMovieDetailUseCase = getMovieDetailUseCase
        self.getTVShowDetailUseCase = getTVShowDetailUseCase
        self.toggleFavoriteUseCase = toggleFavoriteUseCase
        self.appNavigator = appNavigator

        // Observe changes to searchQuery and perform search with a debounce
        $searchQuery
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main) // Wait 0.5s after user stops typing
            .removeDuplicates() // Prevent searching for the same query repeatedly
            .sink { [weak self] query in
                guard let self = self else { return }
                Task { @MainActor in // Ensure search operation runs on the main actor
                    await self.performSearch(query: query)
                }
            }
            .store(in: &cancellables) // Store the Combine subscription
    }

    public func performSearch(query: String) async {
        searchTask?.cancel() // Cancel any ongoing search task

        isLoading = true
        errorMessage = nil

        searchTask = Task { @MainActor in // Create a new task for the search operation
            guard !query.isEmpty else {
                self.movieResults = []
                self.tvShowResults = []
                isLoading = false
                return
            }

            do {
                self.movieResults = try await searchMoviesUseCase.execute(query: query, page: 1)
                self.tvShowResults = try await searchTVShowsUseCase.execute(query: query, page: 1)
            } catch {
                errorMessage = "Failed to search: \(error.localizedDescription)"
                print("Error searching: \(error)")
            }
            isLoading = false
        }
    }

    public func toggleMovieFavorite(movie: MovieEntity) async {
        do {
            try await toggleFavoriteUseCase.execute(movieId: movie.id, isFavorite: !movie.isFavorite)
            // Update local state directly for better UX
            if let index = movieResults.firstIndex(where: { $0.id == movie.id }) {
                movieResults[index].isFavorite.toggle()
            }
        } catch {
            errorMessage = "Failed to toggle movie favorite: \(error.localizedDescription)"
            print("Error toggling movie favorite: \(error)")
        }
    }
    
    public func toggleTVShowFavorite(tvShow: TVShowEntity) async {
        do {
            try await toggleFavoriteUseCase.execute(tvShowId: tvShow.id, isFavorite: !tvShow.isFavorite)
            // Update local state directly for better UX
            if let index = tvShowResults.firstIndex(where: { $0.id == tvShow.id }) {
                tvShowResults[index].isFavorite.toggle()
            }
        } catch {
            errorMessage = "Failed to toggle TV Show favorite: \(error.localizedDescription)"
            print("Error toggling TV Show favorite: \(error)")
        }
    }
    public func navigateToMovieDetail(movieId: Int) {
        appNavigator.dismissGlobalRoute() // Dismiss the search screen
      appNavigator.navigate(to: .movieDetail(movieId: movieId), inTab: .movies) // Navigate to detail in movies tab
    }

    public func navigateToTVShowDetail(tvShowId: Int) {
        appNavigator.dismissGlobalRoute() // Dismiss the search screen
      appNavigator.navigate(to: .tvShowDetail(tvShowId: tvShowId), inTab: .tvShows) // Navigate to detail in TV shows tab
    }

    public func dismissSearch() {
        appNavigator.dismissGlobalRoute() // Dismiss the search screen
    }
  
  public func showSheet(for route: AppRoute) {
    appNavigator.presentSheet(route)
  }
}
