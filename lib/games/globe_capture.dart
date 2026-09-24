import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../stats_manager.dart';

class GlobeCaptureGame extends StatefulWidget {
  const GlobeCaptureGame({super.key});

  @override
  State<GlobeCaptureGame> createState() => _GlobeCaptureGameState();
}

class City {
  final String name;
  final String continent;
  final double lat; // Latitude degrees
  final double lon; // Longitude degrees
  final List<String> traits; // Interpol clue markers
  final String timezone;

  City({
    required this.name,
    required this.continent,
    required this.lat,
    required this.lon,
    required this.traits,
    required this.timezone,
  });
}

class _GlobeCaptureGameState extends State<GlobeCaptureGame> with TickerProviderStateMixin {
  // Game Configuration - Comprehensive list of global transit hubs
  final List<City> cities = [
    // Europe
    City(name: "London (UK)", continent: "Europe", lat: 51.5074, lon: -0.1278, traits: ["Big Ben", "Thames River", "Rainy Weather", "Double-decker Buses"], timezone: "GMT+0"),
    City(name: "Paris (France)", continent: "Europe", lat: 48.8566, lon: 2.3522, traits: ["Eiffel Tower", "Louvre Museum", "Seine River", "Croissants"], timezone: "GMT+1"),
    City(name: "Rome (Italy)", continent: "Europe", lat: 41.9028, lon: 12.4964, traits: ["Colosseum", "Vatican City", "Trevi Fountain", "Ancient Pasta"], timezone: "GMT+1"),
    City(name: "Berlin (Germany)", continent: "Europe", lat: 52.5200, lon: 13.4050, traits: ["Brandenburg Gate", "Berlin Wall", "Pretzels", "Spree River"], timezone: "GMT+1"),
    City(name: "Moscow (Russia)", continent: "Europe", lat: 55.7558, lon: 37.6173, traits: ["Red Square", "Kremlin Spire", "Matryoshka Dolls", "Cold Winters"], timezone: "GMT+3"),
    City(name: "Madrid (Spain)", continent: "Europe", lat: 40.4168, lon: -3.7038, traits: ["Plaza Mayor", "Tapas Bars", "Royal Palace", "Flamenco Dancing"], timezone: "GMT+1"),
    City(name: "Athens (Greece)", continent: "Europe", lat: 37.9838, lon: 23.7275, traits: ["Acropolis Citadel", "Parthenon Columns", "Olive Groves", "Aegean Sea"], timezone: "GMT+2"),
    City(name: "Amsterdam (Netherlands)", continent: "Europe", lat: 52.3676, lon: 4.9041, traits: ["Canal Network", "Windmills Field", "Tulips Garden", "Bicycle Pathways"], timezone: "GMT+1"),
    City(name: "Stockholm (Sweden)", continent: "Europe", lat: 59.3293, lon: 18.0686, traits: ["Gamla Stan", "Vasa Museum", "Archipelago Islands", "Baltic Sightings"], timezone: "GMT+1"),
    City(name: "Bern (Switzerland)", continent: "Europe", lat: 46.9480, lon: 7.4474, traits: ["Alpine Peaks", "Chocolate Craft", "Luxury Watches", "Glacier Valleys"], timezone: "GMT+1"),
    City(name: "Kyiv (Ukraine)", continent: "Europe", lat: 50.4501, lon: 30.5234, traits: ["Saint Sophia", "Dnieper River", "Golden Gate", "Sunflower Plains"], timezone: "GMT+2"),
    City(name: "Warsaw (Poland)", continent: "Europe", lat: 52.2297, lon: 21.0122, traits: ["Old Town Market", "Vistula River", "Royal Castle", "Pierogi Dumplings"], timezone: "GMT+1"),
    City(name: "Lisbon (Portugal)", continent: "Europe", lat: 38.7223, lon: -9.1393, traits: ["Belem Tower", "Tagus Estuary", "Tram 28 Route", "Atlantic Cliffs"], timezone: "GMT+0"),
    City(name: "Vienna (Austria)", continent: "Europe", lat: 48.2082, lon: 16.3738, traits: ["Schonbrunn Palace", "Danube Canal", "Viennese Opera", "Alpine Slopes"], timezone: "GMT+1"),
    City(name: "Oslo (Norway)", continent: "Europe", lat: 59.9139, lon: 10.7522, traits: ["Oslofjord Bays", "Viking Ships", "Vigeland Park", "Northern Lights"], timezone: "GMT+1"),
    City(name: "Brussels (Belgium)", continent: "Europe", lat: 50.8503, lon: 4.3517, traits: ["Atomium", "Waffles", "Chocolate", "Grand Place"], timezone: "GMT+1"),
    City(name: "Helsinki (Finland)", continent: "Europe", lat: 60.1699, lon: 24.9384, traits: ["Sauna Culture", "Design District", "Northern Lights Hub", "Lakeside Life"], timezone: "GMT+2"),
    City(name: "Copenhagen (Denmark)", continent: "Europe", lat: 55.6761, lon: 12.5683, traits: ["Little Mermaid", "Nyhavn Harbor", "Tivoli Gardens", "Cycling City"], timezone: "GMT+1"),
    City(name: "Dublin (Ireland)", continent: "Europe", lat: 53.3498, lon: -6.2603, traits: ["Trinity College", "Temple Bar", "Guinness Storehouse", "Rolling Green Hills"], timezone: "GMT+0"),
    City(name: "Prague (Czech Republic)", continent: "Europe", lat: 50.0755, lon: 14.4378, traits: ["Charles Bridge", "Old Town Square", "Prague Castle", "Pilsner Beer"], timezone: "GMT+1"),
    City(name: "Budapest (Hungary)", continent: "Europe", lat: 47.4979, lon: 19.0402, traits: ["Parliament Building", "Thermal Baths", "Danube River", "Goulash"], timezone: "GMT+1"),
    City(name: "Bucharest (Romania)", continent: "Europe", lat: 44.4268, lon: 26.1025, traits: ["Parliament Palace", "Old Town", "Carpathian Mountains", "Dracula Legends"], timezone: "GMT+2"),

    // Africa
    City(name: "Cairo (Egypt)", continent: "Africa", lat: 30.0444, lon: 31.2357, traits: ["Giza Pyramids", "Nile River", "Great Sphinx", "Khan Bazaar"], timezone: "GMT+2"),
    City(name: "Nairobi (Kenya)", continent: "Africa", lat: -1.2921, lon: 36.8219, traits: ["Rift Valley", "Safari Wildlife", "Coffee Plantations", "Equator Proximity"], timezone: "GMT+3"),
    City(name: "Cape Town (South Africa)", continent: "Africa", lat: -33.9249, lon: 18.4241, traits: ["Table Mountain", "Cape of Good Hope", "Robben Island", "Penguin Colony"], timezone: "GMT+2"),
    City(name: "Lagos (Nigeria)", continent: "Africa", lat: 6.5244, lon: 3.3792, traits: ["Lekki Conservation", "Afrobeats Music", "Third Mainland Bridge", "Eko Atlantic"], timezone: "GMT+1"),
    City(name: "Rabat (Morocco)", continent: "Africa", lat: 34.0209, lon: -6.8416, traits: ["Kasbah Forts", "Atlas Mountains", "Spice Markets", "Sahara Dunes"], timezone: "GMT+1"),
    City(name: "Casablanca (Morocco)", continent: "Africa", lat: 33.5731, lon: -7.5898, traits: ["Hassan II Mosque", "Art Deco Architecture", "Atlantic Port", "Rick's Cafe"], timezone: "GMT+1"),
    City(name: "Addis Ababa (Ethiopia)", continent: "Africa", lat: 9.0300, lon: 38.7400, traits: ["Entoto Hills", "Coffee Cradle", "National Museum", "Blue Nile Source"], timezone: "GMT+3"),
    City(name: "Accra (Ghana)", continent: "Africa", lat: 5.6037, lon: -0.1870, traits: ["Black Star Square", "Makola Market", "Atlantic Coastline", "Gold Coast Forts"], timezone: "GMT+0"),
    City(name: "Algiers (Algeria)", continent: "Africa", lat: 36.7525, lon: 3.0420, traits: ["Mediterranean Bay", "Casbah Architecture", "Sahara Borderlines", "Notre Dame d'Afrique"], timezone: "GMT+1"),
    City(name: "Tunis (Tunisia)", continent: "Africa", lat: 36.8065, lon: 10.1815, traits: ["Carthage Ruins", "Medina Plazas", "Mediterranean Sun", "Desert Film Sites"], timezone: "GMT+1"),
    City(name: "Dakar (Senegal)", continent: "Africa", lat: 14.7167, lon: -17.4677, traits: ["Goree Island", "African Renaissance Monument", "Teranga Hospitality", "Pink Lake"], timezone: "GMT+0"),
    City(name: "Abidjan (Ivory Coast)", continent: "Africa", lat: 5.3600, lon: -4.0083, traits: ["Basilica of Our Lady", "Cocoa Hub", "Plateau Skyline", "Lagoon Vistas"], timezone: "GMT+0"),
    City(name: "Tripoli (Libya)", continent: "Africa", lat: 32.8872, lon: 13.1913, traits: ["Sahara Expanses", "Mediterranean Coastline", "Ancient Ruins", "Desert Hubs"], timezone: "GMT+2"),
    City(name: "Khartoum (Sudan)", continent: "Africa", lat: 15.5007, lon: 32.5599, traits: ["Nile Convergence", "Meroe Pyramids", "Nubian Heritage", "Khartoum Junction"], timezone: "GMT+2"),
    City(name: "Bamako (Mali)", continent: "Africa", lat: 12.6392, lon: -8.0029, traits: ["Timbuktu Gateway", "Niger River", "Dogon Country", "Sahel Sands"], timezone: "GMT+0"),
    City(name: "Ouagadougou (Burkina Faso)", continent: "Africa", lat: 12.3714, lon: -1.5197, traits: ["Mossi Kingdom", "FESPACO Film", "Savannah Plains", "Artisan Markets"], timezone: "GMT+0"),
    City(name: "Conakry (Guinea)", continent: "Africa", lat: 9.6412, lon: -13.5784, traits: ["Fouta Djallon", "Bauxite Mines", "Atlantic Port", "Forest Region"], timezone: "GMT+0"),
    City(name: "Freetown (Sierra Leone)", continent: "Africa", lat: 8.484, lon: -13.2344, traits: ["Lion Mountain", "Cotton Tree", "Freetown Harbor", "Diamond Fields"], timezone: "GMT+0"),
    City(name: "Nouakchott (Mauritania)", continent: "Africa", lat: 18.0735, lon: -15.9582, traits: ["Chinguetti Library", "Iron Ore Train", "Nouakchott Coast", "Sahara Border"], timezone: "GMT+0"),
    City(name: "Niamey (Niger)", continent: "Africa", lat: 13.5116, lon: 2.1254, traits: ["Air Mountains", "Agadez Mosque", "Niger River Valley", "Uranium Mines"], timezone: "GMT+1"),
    City(name: "Dar es Salaam (Tanzania)", continent: "Africa", lat: -6.7924, lon: 39.2083, traits: ["Zanzibar Ferry", "Kariakoo Market", "Indian Ocean Breezes", "Coastal Hub"], timezone: "GMT+3"),
    City(name: "Kigali (Rwanda)", continent: "Africa", lat: -1.9441, lon: 30.0619, traits: ["Land of a Thousand Hills", "Gorilla Trekking", "Clean Streets", "Kigali Heights"], timezone: "GMT+2"),
    City(name: "Luanda (Angola)", continent: "Africa", lat: -8.8390, lon: 13.2894, traits: ["Atlantic Harbor", "Fortress of Sao Miguel", "Kalandula Falls", "Mussulo Peninsula"], timezone: "GMT+1"),

    // Asia
    City(name: "Tokyo (Japan)", continent: "Asia", lat: 35.6762, lon: 139.6503, traits: ["Mount Fuji", "Shibuya Crossing", "Sushi Bars", "Neon Lights"], timezone: "GMT+9"),
    City(name: "Beijing (China)", continent: "Asia", lat: 39.9042, lon: 116.4074, traits: ["Great Wall", "Forbidden City", "Giant Pandas", "Imperial Palaces"], timezone: "GMT+8"),
    City(name: "Shanghai (China)", continent: "Asia", lat: 31.2304, lon: 121.4737, traits: ["The Bund", "Oriental Pearl Tower", "Maglev Train", "Skyscraper Forest"], timezone: "GMT+8"),
    City(name: "Mumbai (India)", continent: "Asia", lat: 19.0760, lon: 72.8777, traits: ["Gateway of India", "Bollywood Studios", "Marine Drive", "Spices Market"], timezone: "GMT+5:30"),
    City(name: "Delhi (India)", continent: "Asia", lat: 28.6139, lon: 77.2090, traits: ["Red Fort", "India Gate", "Lotus Temple", "Old Delhi Bazars"], timezone: "GMT+5:30"),
    City(name: "Bangkok (Thailand)", continent: "Asia", lat: 13.7563, lon: 100.5018, traits: ["Grand Palace", "Wat Arun Temple", "Floating Markets", "Tuk-Tuk Cabs"], timezone: "GMT+7"),
    City(name: "Seoul (South Korea)", continent: "Asia", lat: 37.5665, lon: 126.9780, traits: ["Gyeongbokgung Palace", "N Seoul Tower", "Han River", "K-Pop Hubs"], timezone: "GMT+9"),
    City(name: "Jakarta (Indonesia)", continent: "Asia", lat: -6.2088, lon: 106.8456, traits: ["Monas Monument", "Tropical Archipelagos", "Batik Craft", "Sunda Kelapa Harbor"], timezone: "GMT+7"),
    City(name: "Riyadh (Saudi Arabia)", continent: "Asia", lat: 24.7136, lon: 46.6753, traits: ["Kingdom Centre", "Diriyah Ruins", "Desert Oasis Lines", "Arabian Gulf Routes"], timezone: "GMT+3"),
    City(name: "Hanoi (Vietnam)", continent: "Asia", lat: 21.0285, lon: 105.8542, traits: ["Hoan Kiem Lake", "Old Quarter Streets", "Water Puppet Theatre", "Halong Gateways"], timezone: "GMT+7"),
    City(name: "Istanbul (Turkey)", continent: "Asia", lat: 41.0082, lon: 28.9784, traits: ["Hagia Sophia", "Bosphorus Strait", "Grand Bazaar", "Blue Mosque Spire"], timezone: "GMT+3"),
    City(name: "Karachi (Pakistan)", continent: "Asia", lat: 24.8607, lon: 67.0011, traits: ["Clifton Beach", "Mazar-e-Quaid", "Arabian Sea Hub", "Karachi Portway"], timezone: "GMT+5"),
    City(name: "Manila (Philippines)", continent: "Asia", lat: 14.5995, lon: 120.9842, traits: ["Intramuros Walls", "Manila Bay Sunset", "Rizal Park", "Jeepney Transit"], timezone: "GMT+8"),
    City(name: "Singapore", continent: "Asia", lat: 1.3521, lon: 103.8198, traits: ["Marina Bay Sands", "Merlion Fountain", "Gardens by the Bay", "Changi Node"], timezone: "GMT+8"),
    City(name: "Kuala Lumpur (Malaysia)", continent: "Asia", lat: 3.1390, lon: 101.6869, traits: ["Petronas Towers", "Batu Caves", "Multicultural Hub", "Tropical Heat"], timezone: "GMT+8"),
    City(name: "Tehran (Iran)", continent: "Asia", lat: 35.6892, lon: 51.3890, traits: ["Azadi Tower", "Milad Tower", "Ancient History", "Bazaar Culture"], timezone: "GMT+3.5"),
    City(name: "Jerusalem (Israel)", continent: "Asia", lat: 31.7683, lon: 35.2137, traits: ["Western Wall", "Old City Walls", "Tech Center", "Mediterranean Coast"], timezone: "GMT+2"),
    City(name: "Dubai (UAE)", continent: "Asia", lat: 25.2048, lon: 55.2708, traits: ["Burj Khalifa", "Desert Dunes", "Luxury Hub", "Future Museum"], timezone: "GMT+4"),
    City(name: "Doha (Qatar)", continent: "Asia", lat: 25.2854, lon: 51.5310, traits: ["Skyline Views", "Pearl-Qatar", "Islamic Art Museum", "Desert Safaris"], timezone: "GMT+3"),
    City(name: "Baghdad (Iraq)", continent: "Asia", lat: 33.3152, lon: 44.3661, traits: ["Tigris River", "Abbasid Palace", "Victory Arch", "Ancient Mesopotamian Roots"], timezone: "GMT+3"),

    // North America
    City(name: "New York (USA)", continent: "North America", lat: 40.7128, lon: -74.0060, traits: ["Statue of Liberty", "Times Square", "Central Park", "Empire State"], timezone: "GMT-5"),
    City(name: "Los Angeles (USA)", continent: "North America", lat: 34.0522, lon: -118.2437, traits: ["Hollywood Sign", "Santa Monica Pier", "Griffith Observatory", "Palm Trees"], timezone: "GMT-8"),
    City(name: "Chicago (USA)", continent: "North America", lat: 41.8781, lon: -87.6298, traits: ["Cloud Gate", "Willis Tower", "Lake Michigan", "Deep Dish Pizza"], timezone: "GMT-6"),
    City(name: "Toronto (Canada)", continent: "North America", lat: 43.6532, lon: -79.3832, traits: ["CN Tower", "Lake Ontario", "Maple Syrup", "Niagara Region"], timezone: "GMT-5"),
    City(name: "Vancouver (Canada)", continent: "North America", lat: 49.2827, lon: -123.1207, traits: ["Stanley Park", "Granville Island", "Mountain Vistas", "Pacific Coast"], timezone: "GMT-8"),
    City(name: "Mexico City (Mexico)", continent: "North America", lat: 19.4326, lon: -99.1332, traits: ["Zocalo Square", "Teotihuacan Pyramids", "Mariachi Bands", "Aztec Palaces"], timezone: "GMT-6"),
    City(name: "Havana (Cuba)", continent: "North America", lat: 23.1136, lon: -82.3666, traits: ["Malecon Seawall", "Classic Vintage Cars", "Old Havana Plazas", "Cigar Craft"], timezone: "GMT-5"),
    City(name: "Panama City (Panama)", continent: "North America", lat: 8.9833, lon: -79.5167, traits: ["Panama Canal", "Casco Viejo Streets", "Pacific Coastline Lines", "Amador Causeway"], timezone: "GMT-5"),
    City(name: "San Jose (Costa Rica)", continent: "North America", lat: 9.9281, lon: -84.0907, traits: ["National Theatre", "Volcanic Cloud Forests", "Pura Vida Lifestyle", "Ecotourism Nodes"], timezone: "GMT-6"),
    City(name: "Guatemala City (Guatemala)", continent: "North America", lat: 14.6349, lon: -90.5069, traits: ["Mayan Ruins Gateway", "Central Highlands", "Antigua Archways", "Volcanic Lake Vistas"], timezone: "GMT-6"),
    City(name: "Port-au-Prince (Haiti)", continent: "North America", lat: 18.5333, lon: -72.3333, traits: ["Citadelle Laferriere", "Caribbean Resilience", "Tapestry Art", "Sans-Souci Palace"], timezone: "GMT-5"),
    City(name: "Santo Domingo (DR)", continent: "North America", lat: 18.4861, lon: -69.9312, traits: ["Zona Colonial", "Punta Cana Beaches", "Merengue Music", "Baseball Passion"], timezone: "GMT-4"),
    City(name: "Kingston (Jamaica)", continent: "North America", lat: 18.0179, lon: -76.8099, traits: ["Reggae Birthplace", "Blue Mountains", "Dunn's River Falls", "Jerk Cuisine"], timezone: "GMT-5"),
    City(name: "Nassau (Bahamas)", continent: "North America", lat: 25.0443, lon: -77.3504, traits: ["Turquoise Waters", "Atlantis Resort", "Pink Sand Beaches", "Pirate History"], timezone: "GMT-5"),

    // South America
    City(name: "Rio de Janeiro (Brazil)", continent: "South America", lat: -22.9068, lon: -43.1729, traits: ["Christ the Redeemer", "Copacabana Beach", "Sugarloaf Mountain", "Samba Rhythms"], timezone: "GMT-3"),
    City(name: "Sao Paulo (Brazil)", continent: "South America", lat: -23.5505, lon: -46.6333, traits: ["Paulista Avenue", "Ibirapuera Park", "Municipal Market", "Coffee Trade Heritage"], timezone: "GMT-3"),
    City(name: "Buenos Aires (Argentina)", continent: "South America", lat: -34.6037, lon: -58.3816, traits: ["Tango Salons", "Casa Rosada Palace", "La Boca District", "Obelisco Monument"], timezone: "GMT-3"),
    City(name: "Lima (Peru)", continent: "South America", lat: -12.0464, lon: -77.0428, traits: ["Ceviche Cuisine", "Plaza Mayor", "Andean Gateways", "Pacific Ocean Cliffs"], timezone: "GMT-5"),
    City(name: "Bogota (Colombia)", continent: "South America", lat: 4.7110, lon: -74.0721, traits: ["Monserrate Sanctuary", "Gold Museum", "Andean Valley Peaks", "Coffee Axis Fields"], timezone: "GMT-5"),
    City(name: "Santiago (Chile)", continent: "South America", lat: -33.4489, lon: -70.6693, traits: ["San Cristobal Hill", "Andes Mountain Backdrop", "Plaza de Armas", "Pacific Portlines"], timezone: "GMT-4"),
    City(name: "Caracas (Venezuela)", continent: "South America", lat: 10.4806, lon: -66.9036, traits: ["Avila Mountain Lines", "Caribbean Airspace", "Simon Bolivar Birthplace", "Plaza Venezuela"], timezone: "GMT-4"),
    City(name: "Quito (Ecuador)", continent: "South America", lat: -0.1807, lon: -78.4678, traits: ["Middle of the World", "Cotopaxi Volcano Lookout", "Colonial Old Quarter", "Andean Ridge Transit"], timezone: "GMT-5"),
    City(name: "La Paz (Bolivia)", continent: "South America", lat: -16.4897, lon: -68.1193, traits: ["Salar de Uyuni", "High Altitude Capital", "Lake Titicaca", "Tiwanaku Ruins"], timezone: "GMT-4"),
    City(name: "Montevideo (Uruguay)", continent: "South America", lat: -34.9011, lon: -56.1645, traits: ["La Rambla", "Mate Culture", "Colonia del Sacramento", "Punta del Este"], timezone: "GMT-3"),
    City(name: "Asuncion (Paraguay)", continent: "South America", lat: -25.2637, lon: -57.5759, traits: ["Panteon de los Heroes", "Guarani Heritage", "Itaipu Dam Gateway", "River Portlife"], timezone: "GMT-4"),

    // Oceania
    City(name: "Sydney (Australia)", continent: "Oceania", lat: -33.8688, lon: 151.2093, traits: ["Sydney Opera House", "Harbour Bridge", "Bondi Surfing", "Kangaroo Sanctuary"], timezone: "GMT+11"),
    City(name: "Melbourne (Australia)", continent: "Oceania", lat: -37.8136, lon: 144.9631, traits: ["Great Ocean Road", "Coffee Capital", "Street Art Lanes", "Yarra River"], timezone: "GMT+11"),
    City(name: "Perth (Australia)", continent: "Oceania", lat: -31.9505, lon: 115.8605, traits: ["Swan River", "Kings Park", "Indian Ocean Sunset", "Quokkas Nearby"], timezone: "GMT+8"),
    City(name: "Auckland (New Zealand)", continent: "Oceania", lat: -36.8485, lon: 174.7633, traits: ["Sky Tower Spire", "Volcanic Cones", "Hauraki Gulf Cruise", "Maori Heritage"], timezone: "GMT+13"),
    City(name: "Suva (Fiji)", continent: "Oceania", lat: -18.1248, lon: 178.4501, traits: ["Coral Coast Gateway", "Pacific Lagoon Reefs", "Suva Harbor Node", "Tropical Rainforest Trails"], timezone: "GMT+12"),
    City(name: "Port Moresby (PNG)", continent: "Oceania", lat: -9.4438, lon: 147.1803, traits: ["Coral Sea Outlook", "Owen Stanley Ranges", "Port Moresby Coastal", "Melanesian Heritage"], timezone: "GMT+10"),
    City(name: "Noumea (New Caledonia)", continent: "Oceania", lat: -22.2735, lon: 166.4481, traits: ["Coral Lagoon", "French Pacific Charm", "Kanak Culture", "Isle of Pines"], timezone: "GMT+11"),
  ];

  final List<Map<String, String>> highValueProducts = [
    {"name": "The Phantom Star Diamond", "desc": "A priceless flawless mineral glowing with light reflection."},
    {"name": "Mona Lisa Copy Code", "desc": "Cryptographic digital art string encoded on a quantum flash array."},
    {"name": "Imperial Jade Dragon Scroll", "desc": "Ancient dynasty map charting clandestine silk routes."},
    {"name": "The Golden Fleece Codec", "desc": "Sub-orbital satellite hijacking firmware package."},
    {"name": "Antimatter Prototype Core", "desc": "A fragile magnetic containment microcapsule field."},
  ];

  // Game Core State variables
  bool showLobbySetup = true;
  bool showProductSelection = false;
  bool isThiefTurn = true;
  bool isHandoff = false;
  int hoursRemaining = 120;
  int _maxOperationalTime = 120;
  int packagesDelivered = 0;
  int thiefMovesCount = 0;

  // Zoom and Interaction State
  double zoomScale = 1.0;
  double _baseZoomScale = 1.0;
  Offset _lastFocalPoint = Offset.zero;

  // Player Names
  String thiefName = "The Phantom";
  String investigatorName = "Interpol Agent";

  final TextEditingController _thiefController = TextEditingController(text: "The Phantom");
  final TextEditingController _investigatorController = TextEditingController(text: "Agent Smith");

  late City thiefLocation;
  late City investigatorLocation;
  late List<City> targets; // Secret list of targets
  List<String> chosenProducts = [];
  City? selectedCity;
  List<String> intelLogs = [];
  List<City> thiefHistory = [];
  List<City> investigatorHistory = [];

  bool gameFinished = false;
  String winReason = "";

  // 3D Engine Rotation state (Pitch and Yaw)
  double rotationX = 0.3; // Initial view tilting slightly downward
  double rotationY = 0.0;

  late AnimationController _pulseController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    // Smooth animation refresh timer for pulsing map elements
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) setState(() {});
    });
    
    _setupGame();
  }

  @override
  void dispose() {
    _thiefController.dispose();
    _investigatorController.dispose();
    _pulseController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _setupGame() {
    final random = Random();

    // Group cities by continent
    Map<String, List<City>> continentGroups = {};
    for (var c in cities) {
      continentGroups.putIfAbsent(c.continent, () => []).add(c);
    }

    List<String> shuffledContinents = continentGroups.keys.toList();
    shuffledContinents.shuffle(random);

    targets = [];
    chosenProducts = [];
    
    // Select 3 random cities from 3 different continents as per spec
    for (int i = 0; i < 3; i++) {
      String cont = shuffledContinents[i];
      List<City> optionList = continentGroups[cont]!;
      targets.add(optionList[random.nextInt(optionList.length)]);
      
      // Assign a random product for each target if needed, or just 1 main list
      chosenProducts.add(highValueProducts[random.nextInt(highValueProducts.length)]["name"]!);
    }

    // Start Thief at a random location that isn't any of the targets
    List<City> nonTargetCities = cities.where((c) => !targets.contains(c)).toList();
    thiefLocation = nonTargetCities[random.nextInt(nonTargetCities.length)];

    // Default Investigator starting position
    investigatorLocation = thiefLocation;

    hoursRemaining = _maxOperationalTime;
    packagesDelivered = 0;
    thiefMovesCount = 0;
    zoomScale = 1.0;
    isThiefTurn = true;
    isHandoff = false;
    gameFinished = false;
    showLobbySetup = true;
    showProductSelection = false;
    selectedCity = thiefLocation;
    thiefHistory = [thiefLocation];
    investigatorHistory = [investigatorLocation];

    intelLogs = [
      "🚨 INTERPOL INTELLIGENCE BULLETIN: High-value espionage active.",
      "Suspect tracked infiltrating transport hubs in the ${thiefLocation.continent} sector.",
      "Time is critical. $_maxOperationalTime Hours remain before international borders lock down."
    ];

    _centerGlobeOnCity(thiefLocation);
    StatsManager().recordGamePlay('GLOBE CAPTURE');
  }

  void _centerGlobeOnCity(City city) {
    setState(() {
      rotationY = -city.lon * pi / 180;
      rotationX = city.lat * pi / 180;
    });
  }

  double _calculateDistance(City c1, City c2) {
    double lat1 = c1.lat * pi / 180;
    double lon1 = c1.lon * pi / 180;
    double lat2 = c2.lat * pi / 180;
    double lon2 = c2.lon * pi / 180;

    double dlon = lon2 - lon1;
    double dlat = lat2 - lat1;

    double a = sin(dlat / 2) * sin(dlat / 2) +
        cos(lat1) * cos(lat2) * sin(dlon / 2) * sin(dlon / 2);
    return 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  int _getTravelCostHours(City from, City to, String mode) {
    if (from == to) return 0;
    double dist = _calculateDistance(from, to);

    if (mode == 'rail') {
      // Railway: 10 to 30 hrs (varies by km & speed)
      int cost = 10 + ((dist / pi) * 20).round();
      return cost.clamp(10, 30);
    } else if (mode == 'regional') {
      // Regional Flight: 5 hrs
      return 5;
    } else {
      // Intercontinental Flight: 20 to 50 hrs (varies by km)
      int cost = 20 + ((dist / pi) * 30).round();
      return cost.clamp(20, 50);
    }
  }

  void _thiefExecuteMove(City destination, String mode) {
    if (gameFinished) return;

    if (thiefMovesCount == 0 && destination == targets[0]) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            "SITE SECURITY TOO HIGH: Perform a scouting move before infiltrating target location.",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    if (destination == targets[packagesDelivered] && hoursRemaining > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.amberAccent,
          content: Text(
            "TARGET LOCK: ${destination.name.toUpperCase()} security alert high. Infiltration required below 20 HRS.",
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    int costHours = _getTravelCostHours(thiefLocation, destination, mode);

    setState(() {
      thiefMovesCount++;
      hoursRemaining -= costHours;
      thiefLocation = destination;
      thiefHistory.add(destination);

      _generateIntelLogs(thiefLocation, destination, mode);

      if (hoursRemaining <= 0) {
        gameFinished = true;
        winReason = "OPERATIONAL TIME EXPIRED: THE PHANTOM ELUDED CAPTURE!";
      } else {
        isHandoff = true;
      }
    });

    HapticFeedback.mediumImpact();
  }

  void _thiefDeliverPackage() {
    if (gameFinished || thiefLocation != targets[packagesDelivered]) return;

    setState(() {
      hoursRemaining -= 5;
      String product = chosenProducts[packagesDelivered];
      packagesDelivered++;

      investigatorLocation = thiefLocation;

      intelLogs.add("🚨 CRITICAL ALERT: [$product] successfully delivered in ${thiefLocation.name}!");
      
      if (packagesDelivered >= 3) {
        gameFinished = true;
        winReason = "HEIST SUCCESSFUL: ALL ARTIFACTS DELIVERED. THE PHANTOM HAS ELUDED INTERPOL!";
        StatsManager().recordWin();
      } else {
        intelLogs.add("Next target continent authorized. operational parameters updated.");
        isHandoff = true;
      }
    });

    HapticFeedback.heavyImpact();
  }

  void _investigatorExecuteArrest(City guess) {
    if (gameFinished) return;

    setState(() {
      investigatorLocation = guess;
      investigatorHistory.add(guess);

      if (guess == thiefLocation && hoursRemaining >= 20) {
        gameFinished = true;
        winReason = "PHANTOM CAPTURED! ARRESTED IN ${guess.name.toUpperCase()}!";
        StatsManager().recordWin();
      } else if (guess == thiefLocation && hoursRemaining < 20) {
        intelLogs.add("❌ ARREST FAILURE: Suspect detected in ${guess.name} but utilized a local SECURE HAVEN.");
        isHandoff = true;
      } else if (hoursRemaining <= 0) {
        gameFinished = true;
        winReason = "OPERATIONAL TIME EXPIRED: THE PHANTOM ELUDED CAPTURE!";
      } else {
        intelLogs.add("❌ ARREST FAILURE: Search warrant executed in ${guess.name} turned up negative.");
        isHandoff = true;
      }
    });

    HapticFeedback.heavyImpact();
  }

  void _generateIntelLogs(City from, City to, String mode) {
    final random = Random();
    String transitIntel = "";
    String geoIntel = "";
    String culturalIntel = "";

    if (mode == 'intercontinental') {
      transitIntel = "Flight Logs: Suspect boarded a flight from ${from.timezone} to ${to.timezone}.";
    } else if (mode == 'regional') {
      transitIntel = "Airspace Radar: Regional flight detected in ${to.continent}.";
    } else {
      transitIntel = "Border Sighting: Suspect took low-visibility rail near ${to.name}.";
    }

    if (to.continent == "Europe") {
      geoIntel = "Intel Feed: Informant places suspect in Nordic or Western European region.";
    } else if (to.continent == "Africa") {
      geoIntel = "Intel Feed: Ground tracker picked up traces near an African hub.";
    } else if (to.continent == "Asia") {
      geoIntel = "Intel Feed: Signals intelligence intercepted data near an Asian megalopolis.";
    } else {
      geoIntel = "Intel Feed: Satellite sweeps detected traffic in the ${to.continent} hemisphere.";
    }

    String randomTrait = to.traits[random.nextInt(to.traits.length)];
    culturalIntel = "Sighting: Security cameras caught glimpse of suspect near location famous for $randomTrait.";

    intelLogs.add("--- TRANSIT ENTRY #${(intelLogs.length ~/ 3) + 1} ---");
    intelLogs.add(transitIntel);
    intelLogs.add(geoIntel);
    intelLogs.add(culturalIntel);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04040C),
      body: Stack(
        children: [
          Positioned.fill(child: _buildGlobeView()),

          if (!showLobbySetup && !showProductSelection)
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(flex: 4, child: _buildTopLeftHUD()),
                      const SizedBox(width: 16),
                      Expanded(flex: 5, child: _buildTopRightHUD()),
                    ],
                  ),
                ),
              ),
            ),

          if (!showLobbySetup && !showProductSelection)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: SafeArea(child: _buildBottomActionPanel()),
            ),

          if (isHandoff && !showLobbySetup && !showProductSelection)
            Positioned.fill(child: _buildHandoffScreen()),

          if (showLobbySetup)
            Positioned.fill(child: _buildLobbySetupScreen()),

          if (showProductSelection)
            Positioned.fill(child: _buildProductSelectionScreen()),

          if (gameFinished && !showLobbySetup && !showProductSelection)
            Positioned.fill(child: _buildEndScreen()),
        ],
      ),
    );
  }

  Widget _buildTopLeftHUD() {
    Color themeColor = isThiefTurn ? Colors.greenAccent : Colors.cyanAccent;
    double progress = (hoursRemaining / _maxOperationalTime).clamp(0.0, 1.0);
    String activePlayerName = isThiefTurn ? thiefName.toUpperCase() : investigatorName.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xEE0B0C16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeColor.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: themeColor.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(isThiefTurn ? Icons.gavel_rounded : Icons.security_rounded, color: themeColor, size: 14),
              const SizedBox(width: 6),
              Expanded(child: Text(activePlayerName, overflow: TextOverflow.ellipsis, style: TextStyle(color: themeColor, fontSize: 11, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 10),
          Text("$hoursRemaining HOURS", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(height: 6, child: LinearProgressIndicator(value: progress, backgroundColor: Colors.white10, color: hoursRemaining > 40 ? themeColor : Colors.redAccent)),
          ),
          const SizedBox(height: 4),
          const Text("OPERATIONAL TIME REMAINING", style: TextStyle(color: Colors.white38, fontSize: 8)),
        ],
      ),
    );
  }

  Widget _buildTopRightHUD() {
    Color themeColor = isThiefTurn ? Colors.pinkAccent : Colors.cyanAccent;
    return Container(
      height: 145,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xEE0B0C16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isThiefTurn ? "MANIFEST CONTENT" : "INTERPOL INTEL BOX", style: TextStyle(color: themeColor, fontSize: 11, fontWeight: FontWeight.bold)),
              Icon(Icons.diamond_rounded, size: 14, color: packagesDelivered > 0 ? Colors.pinkAccent : Colors.white10),
            ],
          ),
          const Divider(color: Colors.white10, height: 12),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: isThiefTurn ? 1 : intelLogs.length,
              itemBuilder: (context, index) {
                if (isThiefTurn) {
                  String currentProd = chosenProducts.isNotEmpty ? (packagesDelivered < chosenProducts.length ? chosenProducts[packagesDelivered] : "N/A") : "None";
                  String currentTgt = targets.isNotEmpty ? (packagesDelivered < targets.length ? targets[packagesDelivered].name : "COMPLETE") : "None";
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("MISSION PROGRESS: $packagesDelivered / 3", style: const TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("ACTIVE TARGET: $currentProd", style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                      Text("DROP OFF POINT: $currentTgt", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  );
                }
                int revIndex = intelLogs.length - 1 - index;
                String logText = intelLogs[revIndex];
                bool isHeader = logText.startsWith("---");
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: Text(logText, style: TextStyle(color: isHeader ? Colors.amberAccent : Colors.white70, fontSize: isHeader ? 10 : 11, fontFamily: 'monospace')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobeView() {
    return LayoutBuilder(builder: (context, constraints) {
      double centerSize = min(constraints.maxWidth, constraints.maxHeight) * 0.94;
      double radius = (centerSize / 2) * zoomScale;
      Offset center = Offset(constraints.maxWidth / 2, constraints.maxHeight * 0.48);

      return GestureDetector(
        onScaleStart: (details) { _baseZoomScale = zoomScale; _lastFocalPoint = details.focalPoint; },
        onScaleUpdate: (details) {
          setState(() {
            zoomScale = (_baseZoomScale * details.scale).clamp(0.5, 12.0);
            Offset delta = details.focalPoint - _lastFocalPoint;
            rotationY += delta.dx * 0.003 / zoomScale.clamp(1.0, 5.0);
            rotationX -= delta.dy * 0.003 / zoomScale.clamp(1.0, 5.0);
            if (rotationX < -pi / 2.2) rotationX = -pi / 2.2;
            if (rotationX > pi / 2.2) rotationX = pi / 2.2;
            _lastFocalPoint = details.focalPoint;
          });
        },
        onTapUp: (details) {
          Offset localPos = details.localPosition;
          City? hitCity;
          double bestDistance = 40.0;
          for (var city in cities) {
            double latRad = city.lat * pi / 180;
            double lonRad = city.lon * pi / 180;
            double x = radius * cos(latRad) * sin(lonRad);
            double y = -radius * sin(latRad);
            double z = radius * cos(latRad) * cos(lonRad);
            double x1 = x * cos(rotationY) + z * sin(rotationY);
            double z1 = -x * sin(rotationY) + z * cos(rotationY);
            double y2 = y * cos(rotationX) - z1 * sin(rotationX);
            double z2 = y * sin(rotationX) + z1 * cos(rotationX);
            if (z2 > 0) {
              Offset projectedScreenPos = Offset(center.dx + x1, center.dy + y2);
              double currentDist = (localPos - projectedScreenPos).distance;
              if (currentDist < bestDistance) { bestDistance = currentDist; hitCity = city; }
            }
          }
          if (hitCity != null) { setState(() { selectedCity = hitCity; }); HapticFeedback.selectionClick(); }
        },
        child: Container(
          color: Colors.transparent,
          child: CustomPaint(
            painter: Globe3DPainter(
              cities: cities, radius: radius, center: center,
              rotationX: rotationX, rotationY: rotationY,
              thiefLocation: thiefLocation, investigatorLocation: investigatorLocation,
              selectedCity: selectedCity, isThiefTurn: isThiefTurn,
              currentTarget: targets.isNotEmpty ? (packagesDelivered < targets.length ? targets[packagesDelivered] : null) : null, 
              zoomScale: zoomScale,
              thiefHistory: thiefHistory,
              investigatorHistory: investigatorHistory,
            ),
            size: Size(constraints.maxWidth, constraints.maxHeight),
          ),
        ),
      );
    });
  }

  Widget _buildLobbySetupScreen() {
    return Container(
      color: const Color(0xFA050510),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.public, color: Colors.amberAccent, size: 54),
              const SizedBox(height: 16),
              const Text("GLOBE CAPTURE: OPERATIVE BRIEFING", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 40),
              _buildNameInput("PLAYER 1: THE PHANTOM (THIEF)", _thiefController, Colors.greenAccent),
              const SizedBox(height: 16),
              _buildNameInput("PLAYER 2: INTERPOL (INVESTIGATOR)", _investigatorController, Colors.cyanAccent),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _difficultyButton("EASY", 320, Colors.greenAccent),
                const SizedBox(width: 16),
                _difficultyButton("HARD", 120, Colors.redAccent),
              ]),
              const SizedBox(height: 40),
              _buildStartButton(),
              const SizedBox(height: 16),
              TextButton.icon(onPressed: _showAboutDialog, icon: const Icon(Icons.info_outline, color: Colors.white38, size: 16), label: const Text("ABOUT & RULES", style: TextStyle(color: Colors.white38, fontSize: 12))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameInput(String label, TextEditingController controller, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),
        TextField(
          controller: controller, style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(filled: true, fillColor: Colors.black26, hintText: "Enter Alias...", enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white10))),
        ),
      ]),
    );
  }

  Widget _buildStartButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) => Container(
        width: double.infinity,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.amberAccent.withOpacity(0.2 * _pulseController.value), blurRadius: 15)]),
        child: ElevatedButton.icon(
          onPressed: () {
            setState(() {
              thiefName = _thiefController.text.trim().isEmpty ? "The Phantom" : _thiefController.text.trim();
              investigatorName = _investigatorController.text.trim().isEmpty ? "Interpol Agent" : _investigatorController.text.trim();
              hoursRemaining = _maxOperationalTime;
              isThiefTurn = true; showLobbySetup = false; showProductSelection = true;
            });
          },
          icon: const Icon(Icons.rocket_launch_rounded), label: const Text("INITIALIZE NETWORK HEIST"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)),
        ),
      ),
    );
  }

  Widget _buildProductSelectionScreen() {
    return Container(
      color: const Color(0xFE050814),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.gavel_rounded, color: Colors.greenAccent, size: 44),
            const SizedBox(height: 12),
            Text("${thiefName.toUpperCase()}'S HEIST MANIFEST", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text("TARGETS IDENTIFIED ACROSS 3 CONTINENTS", style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2)),
            const SizedBox(height: 24),
            ...targets.asMap().entries.map((entry) {
              int idx = entry.key;
              City city = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                child: Row(children: [
                  Container(width: 30, height: 30, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle), child: Center(child: Text("${idx+1}", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))),
                  const SizedBox(width: 16),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(city.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(city.continent.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  ]),
                ]),
              );
            }),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => setState(() => showProductSelection = false),
              child: const Text("INITIALIZE PHANTOM PROTOCOL"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 54)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _productTile(Map<String, String> prod) {
    bool isSelected = chosenProducts.contains(prod["name"]);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: isSelected ? Colors.green.withOpacity(0.1) : Colors.black26, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? Colors.greenAccent : Colors.white10)),
      child: ListTile(
        title: Text(prod["name"]!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(prod["desc"]!, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        onTap: () => setState(() { chosenProducts = [prod["name"]!]; }),
      ),
    );
  }

  Widget _buildBottomActionPanel() {
    if (selectedCity == null) return Container(margin: const EdgeInsets.all(16), child: const Text("🌍 SWIPE TO ROTATE • TAP TO INSPECT", textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 11)));
    City city = selectedCity!;
    bool isThiefHere = city == thiefLocation;
    bool isCurrentTarget = packagesDelivered < targets.length && city == targets[packagesDelivered];
    bool sameContinent = (isThiefTurn ? thiefLocation : investigatorLocation).continent == city.continent;

    return Container(
      margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF0C0D1A), borderRadius: BorderRadius.circular(16), border: Border.all(color: isThiefTurn ? Colors.greenAccent.withOpacity(0.3) : Colors.cyanAccent.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text("CURRENTLY IN: ${(isThiefTurn ? thiefLocation : investigatorLocation).name.toUpperCase()}", style: TextStyle(color: isThiefTurn ? Colors.greenAccent : Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(city.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            if (isCurrentTarget && isThiefTurn) const Icon(Icons.stars, color: Colors.amberAccent, size: 20),
          ],
        ),
        const SizedBox(height: 14),
        if (isThiefTurn) _thiefActions(city, isThiefHere, isCurrentTarget, sameContinent) else _investigatorActions(city),
      ]),
    );
  }

  Widget _thiefActions(City city, bool isThiefHere, bool isCurrentTarget, bool sameContinent) {
    if (isThiefHere) {
      if (isCurrentTarget) return ElevatedButton(onPressed: _thiefDeliverPackage, child: const Text("DELIVER ARTIFACT"));
      return Text(hoursRemaining < 20 ? "🔒 SECURE HAVEN ACTIVE" : "⚠️ EXPOSED: SUSPECT LOCATED", style: TextStyle(color: hoursRemaining < 20 ? Colors.greenAccent : Colors.amberAccent, fontWeight: FontWeight.bold));
    }
    if (isCurrentTarget && hoursRemaining > 20) return const Text("🚨 BORDER LOCK: TARGET INACCESSIBLE", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold));
    
    String airMode = sameContinent ? 'regional' : 'intercontinental';
    int railCost = _getTravelCostHours(thiefLocation, city, 'rail');
    int airCost = _getTravelCostHours(thiefLocation, city, airMode);
    
    return Column(
      children: [
        Row(children: [
          Expanded(child: _buildTravelButton(label: "RAIL", hours: railCost, icon: Icons.train, onPressed: () => _thiefExecuteMove(city, 'rail'))),
          const SizedBox(width: 8),
          Expanded(child: _buildTravelButton(label: "FLIGHT", hours: airCost, icon: Icons.flight, onPressed: () => _thiefExecuteMove(city, airMode))),
        ]),
        const SizedBox(height: 8),
        Text(sameContinent ? "REGIONAL TRANSIT AVAILABLE" : "INTERCONTINENTAL FLIGHT REQUIRED", style: const TextStyle(color: Colors.white38, fontSize: 9)),
      ],
    );
  }

  Widget _investigatorActions(City city) {
    return ElevatedButton(onPressed: () => _investigatorExecuteArrest(city), child: const Text("EXECUTE ARREST WARRANT"));
  }

  Widget _buildTravelButton({required String label, required int hours, required IconData icon, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed, 
      icon: Icon(icon, size: 14), 
      label: Text("$label ($hours H)", style: const TextStyle(fontSize: 11)), 
      style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, padding: const EdgeInsets.symmetric(vertical: 12))
    );
  }

  Widget _buildHandoffScreen() {
    String next = isThiefTurn ? investigatorName : thiefName;
    Color color = isThiefTurn ? Colors.cyanAccent : Colors.greenAccent;
    return Container(
      color: Colors.black.withOpacity(0.95),
      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(isThiefTurn ? Icons.security : Icons.person, color: color, size: 64),
        const SizedBox(height: 20),
        Text("PASS TO ${next.toUpperCase()}", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),
        ElevatedButton(onPressed: () => setState(() { isThiefTurn = !isThiefTurn; isHandoff = false; _centerGlobeOnCity(isThiefTurn ? thiefLocation : investigatorLocation); }), child: const Text("START TURN")),
      ])),
    );
  }

  Widget _buildEndScreen() {
    bool win = winReason.contains("SUCCESSFUL") || winReason.contains("CAPTURED");
    bool thiefWon = winReason.contains("SUCCESSFUL");
    Color color = thiefWon ? Colors.greenAccent : Colors.pinkAccent;
    
    return Container(
      color: Colors.black.withOpacity(0.95),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(thiefWon ? Icons.emoji_events : Icons.security, color: color, size: 64),
        const SizedBox(height: 24),
        Text(thiefWon ? "MISSION ACCOMPLISHED" : "MISSION FAILED", style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(winReason, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: _setupGame, 
          child: const Text("RETURN TO BASE"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16)),
        ),
      ])),
    );
  }

  void _showAboutDialog() {
    showDialog(context: context, builder: (c) => AlertDialog(
      backgroundColor: const Color(0xFF0C0D1A),
      title: const Text("MISSION PARAMETERS", style: TextStyle(color: Colors.amberAccent)),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("THE PHANTOM (Thief):", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            Text("1. Scout locations to find your secret objective.\n2. Infiltrate the target city when time is below 20 HRS.\n3. Deliver the artifact to win.", style: TextStyle(color: Colors.white70)),
            SizedBox(height: 12),
            Text("INTERPOL (Investigator):", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            Text("1. Use intelligence logs to track suspect movements.\n2. Intercept the suspect in their current location to arrest.\n3. Arresting when time is < 20 HRS is harder (Secure Haven).", style: TextStyle(color: Colors.white70)),
            SizedBox(height: 12),
            Text("CONTROLS:", style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
            Text("• PINCH to zoom into clusters.\n• SWIPE to rotate the globe.\n• TAP cities to inspect and travel.", style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("UNDERSTOOD"))],
    ));
  }

  Widget _difficultyButton(String label, int time, Color color) {
    bool isSelected = _maxOperationalTime == time;
    return GestureDetector(
      onTap: () {
        setState(() => _maxOperationalTime = time);
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.black26,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : color.withOpacity(0.3), width: isSelected ? 2 : 1),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8)] : [],
        ),
        child: Text(label, style: TextStyle(color: isSelected ? color : color.withOpacity(0.6), fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }
}

class Globe3DPainter extends CustomPainter {
  final List<City> cities; final double radius; final Offset center; final double rotationX; final double rotationY;
  final City thiefLocation; final City investigatorLocation; final City? selectedCity; final bool isThiefTurn; final City? currentTarget; final double zoomScale;
  final List<City> thiefHistory;
  final List<City> investigatorHistory;

  Globe3DPainter({required this.cities, required this.radius, required this.center, required this.rotationX, required this.rotationY, required this.thiefLocation, required this.investigatorLocation, required this.selectedCity, required this.isThiefTurn, required this.currentTarget, required this.zoomScale, required this.thiefHistory, required this.investigatorHistory});

  // High-fidelity continent silhouettes for a realistic Earth look
  static final Map<String, List<Offset>> earthSkins = {
    "North America": [
      Offset(72, -165), Offset(83, -120), Offset(83, -70), Offset(70, -55), 
      Offset(50, -50), Offset(45, -65), Offset(35, -75), Offset(25, -80), 
      Offset(18, -95), Offset(10, -85), Offset(7, -78), Offset(9, -83), 
      Offset(15, -95), Offset(25, -115), Offset(33, -125), Offset(45, -125), 
      Offset(60, -145), Offset(70, -168)
    ],
    "South America": [
      Offset(13, -82), Offset(13, -70), Offset(8, -55), Offset(5, -35), 
      Offset(-10, -35), Offset(-25, -45), Offset(-45, -65), Offset(-56, -67), 
      Offset(-54, -73), Offset(-40, -75), Offset(-20, -82), Offset(5, -82)
    ],
    "Europe": [
      Offset(71, -10), Offset(71, 25), Offset(65, 35), Offset(60, 40), 
      Offset(50, 45), Offset(45, 40), Offset(37, 35), Offset(36, 25), 
      Offset(35, 15), Offset(35, 0), Offset(38, -10), Offset(43, -10), 
      Offset(48, -25), Offset(55, -25), Offset(65, -15)
    ],
    "Africa": [
      Offset(36, -10), Offset(37, 15), Offset(34, 30), Offset(31, 50), 
      Offset(15, 52), Offset(5, 45), Offset(-15, 40), Offset(-35, 30), 
      Offset(-35, 18), Offset(-20, 10), Offset(5, -5), Offset(5, -15), 
      Offset(15, -18), Offset(25, -15), Offset(32, -10)
    ],
    "Asia": [
      Offset(77, 60), Offset(77, 100), Offset(75, 130), Offset(75, 170), 
      Offset(60, 175), Offset(45, 150), Offset(35, 140), Offset(20, 130), 
      Offset(10, 125), Offset(5, 110), Offset(1, 105), Offset(8, 95), 
      Offset(10, 75), Offset(25, 65), Offset(30, 45), Offset(45, 45), 
      Offset(65, 55)
    ],
    "Oceania": [
      Offset(-11, 113), Offset(-12, 130), Offset(-11, 145), Offset(-18, 154), 
      Offset(-28, 154), Offset(-35, 150), Offset(-39, 145), Offset(-38, 130), 
      Offset(-35, 116), Offset(-28, 112), Offset(-18, 112)
    ],
    "Antarctica": [
      Offset(-82, -180), Offset(-82, -120), Offset(-82, -60), Offset(-82, 0), 
      Offset(-82, 60), Offset(-82, 120), Offset(-82, 180), Offset(-90, 180), 
      Offset(-90, -180)
    ],
  };

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Atmosphere/Glow effect (Halo)
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.blue.withOpacity(0.3), Colors.transparent],
        stops: const [0.85, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.15));
    canvas.drawCircle(center, radius * 1.15, glowPaint);

    // 2. Base Globe (Deep Ocean with Lighting)
    final globePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3), // Light source from top-left
        colors: [const Color(0xFF1B2E5A), const Color(0xFF02040A)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, globePaint);

    // 3. Earth Continents (Land with subtle texture simulation)
    final skinPaint = Paint()..color = const Color(0xFF2E8B57).withOpacity(0.4)..style = PaintingStyle.fill;
    final coastPaint = Paint()..color = const Color(0xFF4FA06F).withOpacity(0.6)..style = PaintingStyle.stroke..strokeWidth = 1.5;

    earthSkins.forEach((continent, points) {
      List<Offset> skinPts = [];
      for (var pt in points) {
        double latRad = pt.dx * pi / 180; double lonRad = pt.dy * pi / 180;
        double x = radius * cos(latRad) * sin(lonRad); double y = -radius * sin(latRad); double z = radius * cos(latRad) * cos(lonRad);
        double x1 = x * cos(rotationY) + z * sin(rotationY); double z1 = -x * sin(rotationY) + z * cos(rotationY);
        double y2 = y * cos(rotationX) - z1 * sin(rotationX); double z2 = y * sin(rotationX) + z1 * cos(rotationX);
        if (z2 > -0.1 * radius) skinPts.add(Offset(center.dx + x1, center.dy + y2));
      }
      if (skinPts.length > 2) {
        final path = Path()..moveTo(skinPts.first.dx, skinPts.first.dy);
        for (int i = 1; i < skinPts.length; i++) path.lineTo(skinPts[i].dx, skinPts[i].dy);
        path.close();
        canvas.drawPath(path, skinPaint);
        canvas.drawPath(path, coastPaint);
      }
    });

    // 4. City Lights (Simulate urban clusters on land)
    final lightPaint = Paint()..color = Colors.yellowAccent.withOpacity(0.4);
    for (var city in cities) {
      double latRad = city.lat * pi / 180; double lonRad = city.lon * pi / 180;
      double x = radius * cos(latRad) * sin(lonRad); double y = -radius * sin(latRad); double z = radius * cos(latRad) * cos(lonRad);
      double x1 = x * cos(rotationY) + z * sin(rotationY); double z1 = -x * sin(rotationY) + z * cos(rotationY);
      double y2 = y * cos(rotationX) - z1 * sin(rotationX); double z2 = y * sin(rotationX) + z1 * cos(rotationX);
      if (z2 > 0) {
        canvas.drawCircle(Offset(center.dx + x1, center.dy + y2), 1, lightPaint);
      }
    }

    // 5. Subtle Grid Lines (Meridians & Parallels)
    final gridPaint = Paint()..color = Colors.white.withOpacity(0.08)..style = PaintingStyle.stroke..strokeWidth = 0.4;
    for (double lat = -80; lat <= 80; lat += 20) {
      double r = radius * cos(lat * pi / 180);
      double y = center.dy - radius * sin(lat * pi / 180) * cos(rotationX);
      if (y > center.dy - radius && y < center.dy + radius) canvas.drawCircle(Offset(center.dx, y), r, gridPaint);
    }

    // 5b. Persistent Global Network (Interconnected Infrastructure)
    // To keep it clean, we connect each city to its 2 nearest neighbors in the same continent
    final networkPaint = Paint()..color = Colors.white.withOpacity(0.03)..style = PaintingStyle.stroke..strokeWidth = 0.5;
    for (int i = 0; i < cities.length; i++) {
      City c1 = cities[i];
      List<City> others = cities.where((c) => c != c1 && c.continent == c1.continent).toList();
      others.sort((a, b) => _calculateDistance(c1, a).compareTo(_calculateDistance(c1, b)));
      
      // Connect to 2 nearest continent neighbors
      for (int j = 0; j < 2 && j < others.length; j++) {
        _drawTransitRoute(canvas, c1, others[j], Colors.white.withOpacity(0.05), 0.3, isRail: true);
      }
    }

    City activeLoc = isThiefTurn ? thiefLocation : investigatorLocation;

    // 6. Global Transit Routes (Flight & Rail)
    for (var city in cities) {
      if (city == activeLoc) continue;
      bool sameCont = city.continent == activeLoc.continent;
      
      double dist = _calculateDistance(activeLoc, city);
      if (dist > 1.8 && !sameCont) continue; 

      Color routeColor = sameCont ? Colors.white12 : Colors.blueAccent.withOpacity(0.15);
      double strokeWidth = sameCont ? 0.3 : 1.2;
      
      _drawTransitRoute(canvas, activeLoc, city, routeColor, strokeWidth, isRail: sameCont);
    }

    // 7. Tactical History (Only show current player's own history)
    if (isThiefTurn) {
      // Thief sees their own path in Green/Amber
      for (int i = 0; i < thiefHistory.length - 1; i++) {
        _drawTransitRoute(canvas, thiefHistory[i], thiefHistory[i+1], Colors.greenAccent.withOpacity(0.2), 1.5, isRail: false, isHistory: true);
      }
    } else {
      // Investigator sees their own search path in Cyan
      for (int i = 0; i < investigatorHistory.length - 1; i++) {
        _drawTransitRoute(canvas, investigatorHistory[i], investigatorHistory[i+1], Colors.cyanAccent.withOpacity(0.2), 1.5, isRail: false, isHistory: true);
      }
    }

    // 8. Player & City Markers
    for (var city in cities) {
      double latRad = city.lat * pi / 180; double lonRad = city.lon * pi / 180;
      double x = radius * cos(latRad) * sin(lonRad); double y = -radius * sin(latRad); double z = radius * cos(latRad) * cos(lonRad);
      double x1 = x * cos(rotationY) + z * sin(rotationY); double z1 = -x * sin(rotationY) + z * cos(rotationY);
      double y2 = y * cos(rotationX) - z1 * sin(rotationX); double z2 = y * sin(rotationX) + z1 * cos(rotationX);
      
      if (z2 > 0) {
        Offset pos = Offset(center.dx + x1, center.dy + y2);
        
        // LOGIC: Hide opponent location
        bool isMeHere = isThiefTurn ? (city == thiefLocation) : (city == investigatorLocation);
        bool isSelected = city == selectedCity;
        
        if (isMeHere || isSelected) {
          double pointSize = (isMeHere || isSelected) ? 7 * sqrt(zoomScale) : 5 * sqrt(zoomScale);
          Color baseColor = isMeHere ? (isThiefTurn ? Colors.greenAccent : Colors.cyanAccent) : Colors.amberAccent;
          
          // Glow effect for markers
          canvas.drawCircle(pos, pointSize + 3, Paint()..color = baseColor.withOpacity(0.3)..style = PaintingStyle.fill);
          canvas.drawCircle(pos, pointSize, Paint()..color = baseColor);

          // Add icons for clarity
          IconData icon = isMeHere ? (isThiefTurn ? Icons.person : Icons.security) : Icons.location_city;
          TextPainter iconPainter = TextPainter(
            text: TextSpan(
              text: String.fromCharCode(icon.codePoint),
              style: TextStyle(fontSize: pointSize * 1.3, fontFamily: icon.fontFamily, package: icon.fontPackage, color: Colors.black),
            ),
            textDirection: TextDirection.ltr,
          );
          iconPainter.layout();
          iconPainter.paint(canvas, Offset(pos.dx - iconPainter.width / 2, pos.dy - iconPainter.height / 2));

          if (zoomScale > 1.5 || isSelected || isMeHere) {
            String label = city.name;
            if (isMeHere) label = isThiefTurn ? "[PHANTOM]" : "[INTERPOL]";
            
            final textPainter = TextPainter(
              text: TextSpan(
                text: label,
                style: TextStyle(
                  color: isSelected ? Colors.amberAccent : (isMeHere ? baseColor : Colors.white), 
                  fontSize: (zoomScale > 5 ? 12 : 10), 
                  fontWeight: FontWeight.bold,
                  backgroundColor: Colors.black54,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
              textDirection: TextDirection.ltr,
            );
            textPainter.layout();
            textPainter.paint(canvas, Offset(pos.dx + pointSize + 8, pos.dy - textPainter.height / 2));
          }
        } else {
          // Regular cities as small dots
          double pointSize = 1.5 * sqrt(zoomScale);
          canvas.drawCircle(pos, pointSize, Paint()..color = Colors.white30);
          
          // ALWAYS show city names, with adaptive opacity based on zoom
          double nameOpacity = (zoomScale / 4.0).clamp(0.15, 0.7);
          final textPainter = TextPainter(
            text: TextSpan(
              text: city.name,
              style: TextStyle(
                color: Colors.white.withOpacity(nameOpacity), 
                fontSize: (zoomScale > 4 ? 9 : 7), 
                fontWeight: FontWeight.normal,
                shadows: [Shadow(color: Colors.black.withOpacity(nameOpacity), blurRadius: 2)],
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(pos.dx + pointSize + 3, pos.dy - textPainter.height / 2));
        }
      }
    }
  }

  @override
  bool shouldRepaint(Globe3DPainter oldDelegate) => true;

  double _calculateDistance(City c1, City c2) {
    double lat1 = c1.lat * pi / 180; double lon1 = c1.lon * pi / 180;
    double lat2 = c2.lat * pi / 180; double lon2 = c2.lon * pi / 180;
    double dlon = lon2 - lon1; double dlat = lat2 - lat1;
    double a = sin(dlat / 2) * sin(dlat / 2) + cos(lat1) * cos(lat2) * sin(dlon / 2) * sin(dlon / 2);
    return 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  void _drawTransitRoute(Canvas canvas, City from, City to, Color color, double width, {required bool isRail, bool isHistory = false}) {
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = width;
    if (isRail && !isHistory) {
      // Dotted/Dashed look for rail
      paint.strokeCap = StrokeCap.round;
    }

    double lat1 = from.lat * pi / 180; double lon1 = from.lon * pi / 180;
    double lat2 = to.lat * pi / 180; double lon2 = to.lon * pi / 180;
    
    List<Offset> pts = [];
    int segments = isRail ? 15 : 25;
    
    for (int i = 0; i <= segments; i++) {
      double t = i / segments;
      double clat = lat1 + (lat2 - lat1) * t;
      double clon = lon1 + (lon2 - lon1) * t;
      
      // For flights (non-rail), add altitude arc
      double alt = isRail ? 1.0 : 1.0 + sin(t * pi) * 0.1;
      double curRadius = radius * alt;
      
      double x = curRadius * cos(clat) * sin(clon);
      double y = -curRadius * sin(clat);
      double z = curRadius * cos(clat) * cos(clon);
      
      double x1 = x * cos(rotationY) + z * sin(rotationY);
      double z1 = -x * sin(rotationY) + z * cos(rotationY);
      double y2 = y * cos(rotationX) - z1 * sin(rotationX);
      double z2 = y * sin(rotationX) + z1 * cos(rotationX);
      
      if (z2 > 0) pts.add(Offset(center.dx + x1, center.dy + y2));
      else if (pts.isNotEmpty) {
        _drawPath(canvas, pts, paint, isRail && !isHistory);
        pts = [];
      }
    }
    _drawPath(canvas, pts, paint, isRail && !isHistory);
  }

  void _drawPath(Canvas canvas, List<Offset> points, Paint paint, bool dotted) {
    if (points.length < 2) return;
    if (dotted) {
      for (int i = 0; i < points.length - 1; i += 2) {
        canvas.drawLine(points[i], points[i+1], paint);
      }
    } else {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) path.lineTo(points[i].dx, points[i].dy);
      canvas.drawPath(path, paint);
    }
  }
}
