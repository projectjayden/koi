import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    @State private var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    ))
    @State private var isLoadingLocation = true
    @State private var isLoadingStores = false
    @State private var hasInitializedLocation = false
    @State private var searchQuery: String = ""
    @State private var foodMarkets: [MKMapItem] = []
    @State private var selectedResult: SelectedStore? = nil
    @State private var searchedLocations: [MKMapItem] = []
    @State private var searchRadius: Double = 10000
    @State private var isSearchFocused: Bool = false
    @State private var showingModal = false
    
    @StateObject private var locationManager = LocationManager()
    @StateObject private var searchCompleter = SearchCompleter()

    var body: some View {
        ZStack { // broken up cause swift can't complile too much
            mapView // map
            overlayView // searchbar
            
            if isLoadingLocation || isLoadingStores {
                loadingOverlay
            }
        }
        .task {
            await locationManager.requestLocationPermission() // request location data from phone
        }
        .onChange(of: locationManager.userLocation) { _, newLocation in
            handleLocationChange(newLocation) // handles user loc changes
        }
        .onChange(of: selectedResult?.mapItem) { _, newResult in // handles selectedplace changes
            handleSelectedResultChange(newResult)
        }
        .onChange(of: searchQuery) { _, newValue in // handles search bar changes
            searchCompleter.updateQuery(newValue)
        }
        .sheet(isPresented: $showingModal, onDismiss: { // store modal
            selectedResult = nil
        }) {
            storeDetailSheet
        }    }
    

// BELOW HAS VARIABLES AND FUNCS ALL FOR THE VIEW //
    
    // map variable
    private var mapView: some View {
        Map(position: $position, interactionModes: [.all], selection: .constant(selectedResult?.mapItem)) {
            UserAnnotation()
            foodMarketsAnnotations
            searchedLocationsAnnotations
        }
        .mapStyle(.standard(pointsOfInterest: .including([.foodMarket]), showsTraffic: true))
        .ignoresSafeArea(.all)
        
    }
    
    @MapContentBuilder // nearby annotations + underlining map circle
    private var foodMarketsAnnotations: some MapContent {
        ForEach(foodMarkets, id: \.self) { result in
            createAnnotation(for: result, icon: "cart.fill")
            createMapCircle(for: result)
        }
    }
    
    @MapContentBuilder // searched annotations + underlining map circle
    private var searchedLocationsAnnotations: some MapContent {
        ForEach(searchedLocations, id: \.self) { result in
            createAnnotation(for: result, icon: "magnifyingglass")
            createMapCircle(for: result)
        }
    }
    
    // searchbar overlay
    private var overlayView: some View {
        VStack(spacing: 0) {
            searchBarView
            
            if shouldShowSearchResults {
                searchResultsView
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            Spacer()
        }
        .animation(.easeInOut(duration: 0.2), value: searchCompleter.completions.isEmpty)
    }
    
    // if there are completions and a query, it should show results
    private var shouldShowSearchResults: Bool {
        !searchCompleter.completions.isEmpty && !searchQuery.isEmpty
    }
    
    // store modal
    @ViewBuilder
    private var storeDetailSheet: some View {
        if let selectedStore = selectedResult {
            StoreDetailModal(store: selectedStore, selectedResult: $selectedResult)
                .presentationDetents([.medium, .fraction(0.99)])
                .presentationDragIndicator(.visible)
        }
    }
    
    // creates the map annotations
    private func createAnnotation(for result: MKMapItem, icon: String) -> some MapContent {
        Annotation(
            result.name ?? "Food Market",
            coordinate: result.placemark.coordinate
        ) {
            annotationButton(for: result, icon: icon)
        }
        .tag(result)
    }
    
    // creates the button for the annotations (and handles clicking it)
    private func annotationButton(for result: MKMapItem, icon: String) -> some View {
        Button {
            handleAnnotationTap(for: result)
        } label: {
            annotationIcon(for: result, icon: icon)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // handles when you click the annotation and the change in css
    private func annotationIcon(for result: MKMapItem, icon: String) -> some View {
        let isSelected = selectedResult?.mapItem == result
        
        return Image(systemName: icon)
            .foregroundColor(.white)
            .font(isSelected ? .largeTitle : .title2)
            .padding(isSelected ? 12 : 8)
            .background(isSelected ? Color.blue : Color.green)
            .clipShape(Circle())
            .scaleEffect(isSelected ? 1.2 : 1.0)
            .shadow(color: isSelected ? .black.opacity(0.3) : .clear, radius: 5)
    }
    
    // creates a circle below the annotation
    private func createMapCircle(for result: MKMapItem) -> some MapContent {
        MapCircle(center: result.placemark.coordinate, radius: 10)
            .foregroundStyle(Color.green.opacity(0.2))
            .stroke(Color.green, lineWidth: 2)
    }
    
    // clicking the annotation -> opens modal and recenters camera
    private func handleAnnotationTap(for result: MKMapItem) {
        let storeDetails = createMockStoreDetails(for: result)
        selectedResult = SelectedStore(mapItem: result, details: storeDetails)
        showingModal = true
        
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedResult?.mapItem = result
            position = .camera(MapCamera(
                centerCoordinate: result.placemark.coordinate,
                distance: searchRadius * 0.5,
                heading: 0,
                pitch: 0
            ))
        }
    }
    
    // if the user location changes, more stores pop up
    private func handleLocationChange(_ newLocation: CLLocation?) {
        guard let location = newLocation else { return }
        
        // Only update camera position once when we first get location
        if !hasInitializedLocation {
            withAnimation(.easeInOut(duration: 1.0)) { // Smooth 1-second animation
                position = .camera(MapCamera(
                    centerCoordinate: location.coordinate,
                    distance: searchRadius,
                    heading: 0,
                    pitch: 0
                ))
            }
            hasInitializedLocation = true
            isLoadingLocation = false
        }
        
        searchCompleter.updateRegion(center: location.coordinate, radius: searchRadius)
        
        // Added loading state for store loading
        isLoadingStores = true
        Task {
            await loadNearbyFoodMarkets(at: location.coordinate)
            await MainActor.run {
                isLoadingStores = false
            }
        }
    }
    
    // if you click a search result, it moves the camera there
    private func handleSelectedResultChange(_ newResult: MKMapItem?) {
        if let result = newResult {
            withAnimation(.easeInOut(duration: 0.5)) {
                position = .camera(MapCamera(
                    centerCoordinate: result.placemark.coordinate,
                    distance: searchRadius * 0.5,
                    heading: 0,
                    pitch: 0
                ))
            }
        }
    }
    
    // loading screen bc it takes a while to load
    private var loadingOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    
                    Text(isLoadingLocation ? "Finding your location..." : "Loading nearby stores...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, 16)
                .padding(.bottom, 100)
                
                Spacer()
            }
            Spacer()
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
        .animation(.easeInOut(duration: 0.3), value: isLoadingLocation)
        .animation(.easeInOut(duration: 0.3), value: isLoadingStores)
    }
    
// TESTING FUNCTION -- SHOULD DELETE AND REPLACE
    
    private func createMockStoreDetails(for mapItem: MKMapItem) -> StoreDetails {
         let sampleItems = [
             storeItem(name: "Organic Bananas", brand: "Fresh Farms", price: 2.99, quantity: 1),
             storeItem(name: "Whole Milk", brand: "Dairy Best", price: 3.49, quantity: 1),
             storeItem(name: "Sourdough Bread", brand: "Baker's Choice", price: 4.99, quantity: 1),
             storeItem(name: "Free Range Eggs", brand: "Happy Hens", price: 5.99, quantity: 12)
         ]
         
         let sampleDeals = [
             Deals(
                 type: .percentageOff(20),
                 category: "Organic Produce",
                 itemsAppliedTo: [sampleItems[0]],
                 description: "20% off all organic fruits"
             ),
             Deals(
                 type: .buyXGetYPercentOff(2, 50),
                 category: "Dairy",
                 itemsAppliedTo: [sampleItems[1]],
                 description: "Buy 2 milk products, get 50% off the second"
             )
         ]
         
         return StoreDetails(
             storeTitle: mapItem.name ?? "Local Grocery Store",
             storeDescription: "Your neighborhood grocery store with fresh produce, quality meats, and everyday essentials.",
             storeRating: Double.random(in: 3.5...5.0),
             storeAddress: mapItem.placemark.title ?? "Address not available",
             storeImages: ["store1", "store2", "store3"], // Mock image names
             storeDeals: sampleDeals,
             itemList: sampleItems,
             storeHours: "Mon-Sun: 7:00 AM - 10:00 PM",
             phoneNumber: "+1 (555) 123-4567"
         )
     }
    
    /*
    private func extractStoreDetails(selectedStore: MKMapItem) {
        // takes store details from sqlite database and adds them to selectedResult.details
    }
    */

// MODAL CODE - USES STORE DETAILS AS TYPE//
    
    struct StoreDetailModal: View {
        let store: SelectedStore
        @Binding var selectedResult: SelectedStore?
        @Environment(\.dismiss) private var dismiss
        
        var body: some View {
            NavigationView {
                ScrollView { // Seperated into 6 different sections (heading, info, deals, rating, contact, items to look out for)
                    VStack(spacing: 0) {
                        // Header with store image
                        storeHeaderView
                        
                        // Content sections
                        VStack(spacing: 24) {
                            storeInfoSection
                            dealsSection
                            ratingsSection
                            contactSection
                            itemsSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
                .background(Color(.systemGroupedBackground))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            selectedResult = nil
                            dismiss()
                        }
                        .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
        }
        
        // title and image of store css
        private var storeHeaderView: some View {
            ZStack(alignment: .bottom) {
                // Mock store image background
                RoundedRectangle(cornerRadius: 0)
                    .fill(LinearGradient(
                        colors: [.blue.opacity(0.3), .green.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: 200)
                
                // Store name overlay
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(store.details.storeTitle)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", store.details.storeRating))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        
        // store description section
        private var storeInfoSection: some View {
            modernCard {
                VStack(alignment: .leading, spacing: 16) {
                    sectionHeader("About", icon: "info.circle.fill")
                    
                    Text(store.details.storeDescription)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        infoRow(icon: "location.fill", text: store.details.storeAddress)
                        infoRow(icon: "clock.fill", text: store.details.storeHours)
                    }
                }
            }
        }
        
        // store deals section
        private var dealsSection: some View {
            modernCard {
                VStack(alignment: .leading, spacing: 16) {
                    sectionHeader("Current Deals", icon: "tag.fill")
                    
                    ForEach(store.details.storeDeals.indices, id: \.self) { index in
                        let deal = store.details.storeDeals[index]
                        dealCard(deal: deal)
                    }
                }
            }
        }
        
        // store rating section
        private var ratingsSection: some View {
            modernCard {
                VStack(alignment: .leading, spacing: 16) {
                    sectionHeader("Rating", icon: "star.fill")
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(format: "%.1f", store.details.storeRating))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 2) {
                                ForEach(0..<5) { index in
                                    Image(systemName: index < Int(store.details.storeRating) ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 14))
                                }
                            }
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 8) {
                            Text("Based on")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("142 reviews")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
        
        // store contact section (like phone #)
        private var contactSection: some View {
            modernCard {
                VStack(alignment: .leading, spacing: 16) {
                    sectionHeader("Contact", icon: "phone.fill")
                    
                    HStack {
                        infoRow(icon: "phone.fill", text: store.details.phoneNumber)
                        Spacer()
                        
                        Button(action: {}) {
                            Text("Call")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        
        // items the store has in stock
        private var itemsSection: some View {
            modernCard {
                VStack(alignment: .leading, spacing: 16) {
                    sectionHeader("Featured Items", icon: "cart.fill")
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(store.details.itemList.indices, id: \.self) { index in
                            let item = store.details.itemList[index]
                            itemCard(item: item)
                        }
                    }
                }
            }
        }
    }

// SEARCH BAR //
    
    private var searchBarView: some View {
        HStack(spacing: 12) {
            // Search Icon
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(searchQuery.isEmpty ? .secondary : .primary)
                .animation(.easeInOut(duration: 0.2), value: searchQuery.isEmpty)
            
            // Search TextField
            TextField("Search grocery stores nearby...", text: $searchQuery)
                .font(.system(size: 16, weight: .regular))
                .textFieldStyle(.plain)
                .onSubmit {
                    Task {
                        await performSearch(for: searchQuery)
                        hideKeyboard()
                    }
                }
                .onTapGesture {
                    isSearchFocused = true
                }
            
            // Clear Button
            if !searchQuery.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        searchQuery = ""
                        searchCompleter.updateQuery("")
                        isSearchFocused = false
                        hideKeyboard()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
// SEARCH RESULTS AND APPEARANCE //
    
    private var searchResultsView: some View {
        let limitedCompletions = Array(searchCompleter.completions.prefix(6))
        let enumeratedCompletions = Array(limitedCompletions.enumerated())
        
        return ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(enumeratedCompletions, id: \.element) { index, completion in
                    searchResultRow(
                        completion: completion,
                        isLast: index == limitedCompletions.count - 1
                    )
                }
            }
        }
        .frame(maxHeight: 280)
        .background(searchResultsBackground)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    private var searchResultsBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.ultraThinMaterial)
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            }
    }
    
    private func searchResultRow(completion: MKLocalSearchCompletion, isLast: Bool) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                searchQuery = completion.title
                isSearchFocused = false
                hideKeyboard()
            }
            Task {
                await performSearchFromCompletion(completion)
            }
        } label: {
            HStack(spacing: 16) {
                // Location Icon
                Image(systemName: "location.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                
                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(completion.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if !completion.subtitle.isEmpty {
                        Text(completion.subtitle)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Arrow Icon
                Image(systemName: "arrow.up.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(-45))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
        .background {
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
        }
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(.separator.opacity(0.5))
                    .frame(height: 0.5)
                    .padding(.leading, 56)
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
// SEARCHING FUNCTION BELOW USING MKLocalSearch //
    private func performSearch(for query: String) async {
        guard !query.isEmpty,
              let userLocation = locationManager.userLocation else { return }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: userLocation.coordinate,
            latitudinalMeters: searchRadius * 2,
            longitudinalMeters: searchRadius * 2
        )
        
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            
            await MainActor.run {
                if let firstResult = response.mapItems.first {
                    let isInFoodMarkets = foodMarkets.contains { existing in
                        existing.placemark.coordinate.latitude == firstResult.placemark.coordinate.latitude &&
                        existing.placemark.coordinate.longitude == firstResult.placemark.coordinate.longitude
                    }
                    
                    // If not in foodMarkets, add to searchedLocations
                    if !isInFoodMarkets {
                        // Remove any existing searched locations to keep it clean
                        searchedLocations = [firstResult]
                    }
                    
                    withAnimation {
                        position = .camera(MapCamera(
                            centerCoordinate: firstResult.placemark.coordinate,
                            distance: searchRadius * 0.5,
                            heading: 0,
                            pitch: 0
                        ))
                        selectedResult?.mapItem = firstResult
                    }
                }
            }
        } catch {
            print("Search failed: \(error.localizedDescription)")
        }
    }
    
    // Search Function from the Search Bar
    private func performSearchFromCompletion(_ completion: MKLocalSearchCompletion) async {
        guard let userLocation = locationManager.userLocation else { return }
        
        // Create search request from the completion object directly instead of only the name (as in the previous funct)
        let request = MKLocalSearch.Request(completion: completion)
        request.region = MKCoordinateRegion(
            center: userLocation.coordinate,
            latitudinalMeters: searchRadius * 2,
            longitudinalMeters: searchRadius * 2
        )
        
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            
            await MainActor.run {
                // Since we're using the specific completion, the first result should be correct (that's why this function is necessary)
                if let result = response.mapItems.first {
                    let isInFoodMarkets = foodMarkets.contains { existing in
                        existing.placemark.coordinate.latitude == result.placemark.coordinate.latitude &&
                        existing.placemark.coordinate.longitude == result.placemark.coordinate.longitude
                    }
                    
                    if !isInFoodMarkets {
                        searchedLocations = [result]
                    }
                    
                    withAnimation {
                        position = .camera(MapCamera(
                            centerCoordinate: result.placemark.coordinate,
                            distance: searchRadius * 0.5,
                            heading: 0,
                            pitch: 0
                        ))
                        selectedResult?.mapItem = result
                    }
                }
            }
        } catch {
            print("Search from completion failed: \(error.localizedDescription)")
        }
    }

    // uses distance to find food markets near you
    private func loadNearbyFoodMarkets(at coordinate: CLLocationCoordinate2D) async {
        print("🔍 Starting search at coordinate: \(coordinate)")
        
        // Clear existing results
        await MainActor.run {
            foodMarkets = []
            searchedLocations = []
        }
        
        // Use multiple search terms to find more stores, can add more later
        let searchTerms = ["grocery", "supermarket", "food store", "market", "shopping market", "costco", "mart"]
        
        for term in searchTerms {
            print("🔍 Searching for: \(term)")
            
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = term
            request.region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: searchRadius * 2,
                longitudinalMeters: searchRadius * 2
            )
            
            let search = MKLocalSearch(request: request)
            do {
                let response = try await search.start()
                print("📍 Found \(response.mapItems.count) results for '\(term)'")
                
                await MainActor.run {
                    for item in response.mapItems {
                        // Check if it's a duplicate
                        let isDuplicate = foodMarkets.contains { existing in
                            guard let existingName = existing.name, let newName = item.name else { return false }
                            
                            let distance = CLLocation(
                                latitude: existing.placemark.coordinate.latitude,
                                longitude: existing.placemark.coordinate.longitude
                            ).distance(from: CLLocation(
                                latitude: item.placemark.coordinate.latitude,
                                longitude: item.placemark.coordinate.longitude
                            ))
                            
                            return existingName == newName && distance < 50 // 50 meters threshold
                        }
                        
                        if !isDuplicate {
                            foodMarkets.append(item)
                        }
                    }
                    
                    print("🛒 Total unique markets found so far: \(foodMarkets.count)")
                }
                
            } catch {
                print("❌ Failed to search for \(term): \(error.localizedDescription)")
            }
        }
    }
}

// apple autocomplete class
class SearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var completions: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.pointOfInterest]
        
        // Filter for food-related results
        completer.pointOfInterestFilter = MKPointOfInterestFilter(including: [
            .foodMarket
        ])
    }
    
    func updateQuery(_ query: String) {
        completer.queryFragment = query.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func updateRegion(center: CLLocationCoordinate2D, radius: Double) {
        completer.region = MKCoordinateRegion(
            center: center,
            latitudinalMeters: radius * 2,
            longitudinalMeters: radius * 2
        )
    }
    
    // MARK: - MKLocalSearchCompleterDelegate
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.completions = completer.results
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer failed with error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.completions = []
        }
    }
}

// copy and pasted code for dealing w/ user location (this is a necessity to use CLLocation)
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocationPermission() async {
        await MainActor.run {
            locationManager.requestWhenInUseAuthorization()
            locationManager.requestLocation()
        }
    }
    
    private func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        locationManager.startUpdatingLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }
        
        switch manager.authorizationStatus {
        case .notDetermined:
            print("When user did not yet determined")
        case .restricted:
            print("Restricted by parental control")
        case .denied:
            print("When user select option Don't Allow")
        case .authorizedWhenInUse:
            print("When user select option Allow While Using App or Allow Once")
            startLocationUpdates()
        case .authorizedAlways:
            print("When user select option Allow Always")
            startLocationUpdates()
        default:
            print("default")
        }
    }
    
    func requestLocation() {
        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.userLocation = location
        }
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
}

// builds background of card for each of the different sections
func modernCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                }
        }
}

// the header for the store name and image
func sectionHeader(_ title: String, icon: String) -> some View {
    HStack(spacing: 8) {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.blue)
        
        Text(title)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.primary)
    }
}

// shows address and hours of store
func infoRow(icon: String, text: String) -> some View {
    HStack(spacing: 12) {
        Image(systemName: icon)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.blue)
            .frame(width: 16)
        
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.primary)
    }
}

// card for the deals
func dealCard(deal: Deals) -> some View {
    HStack(spacing: 12) {
        Image(systemName: "tag.fill")
            .font(.system(size: 16))
            .foregroundColor(.orange)
        
        VStack(alignment: .leading, spacing: 4) {
            Text(deal.description)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(deal.category)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        
        Spacer()
    }
    .padding(12)
    .background {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.orange.opacity(0.1))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            }
    }
}

// card for the items
func itemCard(item: storeItem) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        // Mock item image
        RoundedRectangle(cornerRadius: 8)
            .fill(LinearGradient(
                colors: [.green.opacity(0.2), .blue.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(height: 80)
            .overlay {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green.opacity(0.7))
            }
        
        VStack(alignment: .leading, spacing: 4) {
            Text(item.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Text(item.brand)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Text("$\(String(format: "%.2f", item.price))")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.green)
        }
    }
    .padding(12)
    .background {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(.systemBackground))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}

