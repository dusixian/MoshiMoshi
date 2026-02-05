//
//  APIService.swift
//  MoshiMoshi
//
//  Created by Olivia on 2026/1/26.
//


import Foundation

class APIService {
    static let shared = APIService()
    
    private let baseURL = "https://moshi-moshi-sand.vercel.app/api/reservations"
    
    func sendReservation(request: ReservationRequest) async throws -> BackendResponse {
        guard let url = URL(string: baseURL) else {
            throw URLError(.badURL)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(request)
        
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("Sending JSON: \(jsonString)")
        }
        
        urlRequest.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Received: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
             throw URLError(.badServerResponse)
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
             print("Server Error Code: \(httpResponse.statusCode)")
             if let errorResponse = try? JSONDecoder().decode(BackendResponse.self, from: data) {
                 throw NSError(domain: "API", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorResponse.error ?? "Unknown Error"])
             }
             throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let backendResponse = try decoder.decode(BackendResponse.self, from: data)
        return backendResponse
    }
}
