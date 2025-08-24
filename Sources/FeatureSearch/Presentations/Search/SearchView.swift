//
//  SearchView.swift
//  FeatureSearch
//
//  Created by zeekands on 04/07/25.
//


import SwiftUI
import SharedDomain
import SharedUI

public struct SearchView: View {
  @StateObject private var viewModel: SearchViewModel
  
  public init(viewModel: SearchViewModel) {
    _viewModel = StateObject(wrappedValue: viewModel)
  }
  
  public var body: some View {
    VStack {
      TextField("Search movies or TV shows...", text: $viewModel.searchQuery)
        .textFieldStyle(.roundedBorder)
        .padding(.horizontal)
        .autocorrectionDisabled()
      
      ZStack(alignment: .center) {
        if viewModel.isLoading {
          LoadingIndicator()
        } else if let errorMessage = viewModel.errorMessage {
          ErrorView(message: errorMessage, retryAction: {
            Task { await viewModel.performSearch(query: viewModel.searchQuery) }
          })
        } else if viewModel.movieResults.isEmpty && viewModel.tvShowResults.isEmpty && !viewModel.searchQuery.isEmpty {
          ContentUnavailableView("No Results Found", systemImage: "magnifyingglass.slash")
            .padding()
        } else if viewModel.searchQuery.isEmpty {
          ContentUnavailableView("Start Typing to Search", systemImage: "text.magnifyingglass")
            .padding()
        } else {
          searchResultsContent
        }
      }
    }
    .navigationTitle("Search")
  }
  
  // MARK: - Search Results Content
  private var searchResultsContent: some View {
    List {
      if !viewModel.movieResults.isEmpty {
        Section("Movies") {
          ForEach(viewModel.movieResults) { movie in
            SearchMovieRowView(movie: movie, viewModel: viewModel)
              .onTapGesture {
                viewModel.navigateToMovieDetail(movieId: movie.id)
              }
              .contextMenu {
                Button {
                  Task { await viewModel.toggleMovieFavorite(movie: movie) }
                } label: {
                  Label(movie.isFavorite ? "Unfavorite" : "Favorite", systemImage: movie.isFavorite ? "star.slash.fill" : "star.fill")
                }
              }
          }
        }
      }
      
      if !viewModel.tvShowResults.isEmpty {
        Section("TV Shows") {
          ForEach(viewModel.tvShowResults) { tvShow in
            SearchTVShowRowView(tvShow: tvShow, viewModel: viewModel)
              .onTapGesture {
                viewModel.navigateToTVShowDetail(tvShowId: tvShow.id)
              }
              .contextMenu {
                Button {
                  Task { await viewModel.toggleTVShowFavorite(tvShow: tvShow) }
                } label: {
                  Label(tvShow.isFavorite ? "Unfavorite" : "Favorite", systemImage: tvShow.isFavorite ? "star.slash.fill" : "star.fill")
                }
              }
          }
        }
      }
    }
  }
}

public struct SearchMovieRowView: View {
  public let movie: MovieEntity
  @ObservedObject public var viewModel: SearchViewModel // Needed for toggle favorite action
  
  public var body: some View {
    HStack {
      PosterImageView(imagePath: movie.posterPath, imageType: .poster)
        .frame(width: 60, height: 90)
        .cornerRadius(8)
        .shadow(radius: 2)
      
      VStack(alignment: .leading) {
        Text(movie.title)
          .font(.headline)
          .foregroundColor(.textPrimary)
        Text(movie.overview ?? "")
          .font(.subheadline)
          .lineLimit(2)
          .foregroundColor(.textSecondary)
      }
      Spacer()
      if movie.isFavorite {
        Image(systemName: "heart.fill")
          .foregroundColor(.favoriteRed)
      }
      Image(systemName: "chevron.right")
        .foregroundColor(.textSecondary)
    }
    .padding(.vertical, 4)
  }
}

public struct SearchTVShowRowView: View {
  public let tvShow: TVShowEntity
  @ObservedObject public var viewModel: SearchViewModel // Needed for toggle favorite action
  
  public var body: some View {
    HStack {
      PosterImageView(imagePath: tvShow.posterPath, imageType: .poster)
        .frame(width: 60, height: 90)
        .cornerRadius(8)
        .shadow(radius: 2)
      
      VStack(alignment: .leading) {
        Text(tvShow.name)
          .font(.headline)
          .foregroundColor(.textPrimary)
        Text(tvShow.overview ?? "")
          .font(.subheadline)
          .lineLimit(2)
          .foregroundColor(.textSecondary)
      }
      Spacer()
      if tvShow.isFavorite {
        Image(systemName: "heart.fill")
          .foregroundColor(.favoriteRed)
      }
      Image(systemName: "chevron.right")
        .foregroundColor(.textSecondary)
    }
    .padding(.vertical, 4)
  }
}
