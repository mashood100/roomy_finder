const allMaintenances = [
  // Air Conditioner
  {
    "name": "REQUEST ASSESSMENT",
    "category": "Air Conditioner",
    "subCategory": "Central AC",
    "materialIncluded": false,
    "description":
        "Let the technician assess the issue.The amount will be credited to the total invoice"
  },
  {
    "name": "ROUTINE CENTRAL AC MAINTENANCE PACKAGE",
    "category": "Air Conditioner",
    "subCategory": "Central AC",
    "materialIncluded": false
  },
  {
    "name": "EXTENSIVE CENTRAL AC MAINTENANCE PACKAGE",
    "category": "Air Conditioner",
    "subCategory": "Central AC",
    "materialIncluded": false
  },
  {
    "name": "THERMOSTAT REPLACEMENT",
    "category": "Air Conditioner",
    "subCategory": "Central AC",
    "materialIncluded": false
  },
  {
    "name": "GAS LEAK REPAIR",
    "category": "Air Conditioner",
    "subCategory": "Central AC",
    "materialIncluded": false
  },
  {
    "name": "MOTOR CAPACITOR REPLACEMENT",
    "category": "Air Conditioner",
    "subCategory": "Central AC",
    "materialIncluded": false
  },
  {
    "name": "INDOOR BLOWER MOTOR INSTALLATION",
    "category": "Air Conditioner",
    "subCategory": "Central AC",
    "materialIncluded": false
  },
  {
    "name": "OUTDOOR CONDENSER MOTOR INSTALLATION",
    "category": "Air Conditioner",
    "subCategory": "Central AC",
    "materialIncluded": false
  },
  {
    "name": "CONTACTOR REPLACEMENT",
    "category": "Air Conditioner",
    "subCategory": "Central AC",
    "materialIncluded": false
  },
  {
    "name": "R22 GAS FULL CYLINDER - 13.6 KG",
    "category": "Air Conditioner",
    "subCategory": "Central AC",
    "materialIncluded": false
  },
  {
    "name": "R22 GAS HALF CYLINDER - 6.8 KG",
    "category": "Air Conditioner",
    "subCategory": "Central AC",
    "materialIncluded": false
  },
  {
    "name": "R22 GAS QUARTER CYLINDER - 3.4 KG",
    "category": "Air Conditioner",
    "subCategory": "Central AC",
    "materialIncluded": false
  },
  {
    "name": "R410 GAS FULL CYLINDER - 11.3 KG",
    "category": "Air Conditioner",
    "subCategory": "Central AC",
    "materialIncluded": false
  },
  {
    "name": "R410 GAS HALF CYLINDER - 5.6 KG",
    "category": "Air Conditioner",
    "subCategory": "Central AC",
    "materialIncluded": false
  },
  {
    "name": "R22 GAS QUARTER CYLINDER - 2.8 KG",
    "category": "Air Conditioner",
    "subCategory": "Central AC",
    "materialIncluded": false
  },
  {
    "name": "REQUEST ASSESSMENT",
    "category": "Air Conditioner",
    "subCategory": "Split AC",
    "materialIncluded": false,
    "description":
        "Let the technician assess the issue.The amount will be credited to the total invoice"
  },
  {
    "name": "ROUTINE CENTRAL AC MAINTENANCE PACKAGE",
    "category": "Air Conditioner",
    "subCategory": "Split AC",
    "materialIncluded": false
  },
  {
    "name": "EXTENSIVE CENTRAL AC MAINTENANCE PACKAGE",
    "category": "Air Conditioner",
    "subCategory": "Split AC",
    "materialIncluded": false
  },
  {
    "name": "WATER LAKE REPAIR",
    "category": "Air Conditioner",
    "subCategory": "Split AC",
    "materialIncluded": false
  },
  {
    "name": "GAS LEAK REPAIR",
    "category": "Air Conditioner",
    "subCategory": "Split AC",
    "materialIncluded": false
  },
  {
    "name": "PCP BOARD REPLACEMENT",
    "category": "Air Conditioner",
    "subCategory": "Split AC",
    "materialIncluded": false
  },
  {
    "name": "INDOOR BLOWER MOTOR INSTALLATION",
    "category": "Air Conditioner",
    "subCategory": "Split AC",
    "materialIncluded": false
  },
  {
    "name": "OUTDOOR CONDENSER MOTOR INSTALLATION",
    "category": "Air Conditioner",
    "subCategory": "Split AC",
    "materialIncluded": false
  },
  {
    "name": "MOTOR CAPACITOR REPLACEMENT",
    "category": "Air Conditioner",
    "subCategory": "Split AC",
    "materialIncluded": false
  },
  {
    "name": "R22 GAS FULL CYLINDER - 13.6 KG",
    "category": "Air Conditioner",
    "subCategory": "Split AC",
    "materialIncluded": false
  },
  {
    "name": "R22 GAS HALF CYLINDER - 6.8 KG",
    "category": "Air Conditioner",
    "subCategory": "Split AC",
    "materialIncluded": false
  },
  {
    "name": "R22 GAS QUARTER CYLINDER - 3.4 KG",
    "category": "Air Conditioner",
    "subCategory": "Split AC",
    "materialIncluded": false
  },
  {
    "name": "R410 GAS FULL CYLINDER - 11.3 KG",
    "category": "Air Conditioner",
    "subCategory": "Split AC",
    "materialIncluded": false
  },
  {
    "name": "R410 GAS HALF CYLINDER - 5.6 KG",
    "category": "Air Conditioner",
    "subCategory": "Split AC",
    "materialIncluded": false
  },
  {
    "name": "R22 GAS QUARTER CYLINDER - 2.8 KG",
    "category": "Air Conditioner",
    "subCategory": "Split AC",
    "materialIncluded": false
  },
  // Cleaning
  {
    "name": "Studio",
    "category": "Cleaning",
    "subCategory": "Studio",
    "materialIncluded": false,
    "description": ""
  },
  {
    "name": "Partition",
    "category": "Cleaning",
    "subCategory": "Partition",
    "materialIncluded": false,
    "description": ""
  },
  {
    "name": "Room",
    "category": "Cleaning",
    "subCategory": "Room",
    "materialIncluded": false,
    "description": ""
  },
  {
    "name": "House",
    "category": "Cleaning",
    "subCategory": "House",
    "materialIncluded": false,
    "description": ""
  },
  // Electrical
  {
    "name": "REQUEST ASSESSMENT",
    "category": "Electrical",
    "subCategory": "Distribution Board",
    "materialIncluded": false,
    "description":
        "Let the technician assess the issue.The amount will be credited to the total invoice"
  },
  {
    "name": "MAIN CIRCUIT BREAKER INSTALLATION",
    "category": "Electrical",
    "subCategory": "Distribution Board",
    "materialIncluded": false,
    "description":
        "Single-phase or three-phase circuit breakers materials not included"
  },
  {
    "name": "MINI WATER HATER REPLACEMENT",
    "category": "Electrical",
    "subCategory": "Distribution Board",
    "materialIncluded": false,
    "description":
        "Single-phase or three-phase circuit breakers materials not included"
  },
  {
    "name": "REQUEST ASSESSMENT",
    "category": "Electrical",
    "subCategory": "Lighting",
    "materialIncluded": false,
    "description":
        "Let the technician assess the issue. The amount will be credited to the total invoice"
  },
  {
    "name": "CHANDELIER INSTALLATION",
    "category": "Electrical",
    "subCategory": "Lighting",
    "materialIncluded": false,
    "description":
        "Let the technician assess the issue. The amount will be credited to the total invoice"
  },
  {
    "name": "LIGHT BULB REPLACEMENT",
    "category": "Electrical",
    "subCategory": "Lighting",
    "materialIncluded": false,
    "description": "Light bulbs not included"
  },
  {
    "name": "LIGHT FIXTURE INSTALLATION",
    "category": "Electrical",
    "subCategory": "Lighting",
    "materialIncluded": false,
    "description": "Light fixture not included"
  },
  {
    "name": "LIGHT SWITCH REPLACEMENT OR INSTALLATION",
    "category": "Electrical",
    "subCategory": "Lighting",
    "materialIncluded": false,
    "description": "Switch not included"
  },
  {
    "name": "NEW LIGHTING POINT INSTALLATION",
    "category": "Electrical",
    "subCategory": "Lighting",
    "materialIncluded": false,
    "description":
        "Let the technician assess the issue. The amount will be credited to the total invoice"
  },
  {
    "name": "REQUEST ASSESSMENT",
    "category": "Electrical",
    "subCategory": "Switch and power outlets",
    "materialIncluded": false,
    "description":
        "Let the technician assess the issue. The amount will be credited to the total invoice"
  },
  {
    "name": "CONVENTIONAL ELECTRICAL SWITCH REPAIR",
    "category": "Electrical",
    "subCategory": "Switch and power outlets",
    "materialIncluded": false,
    "description":
        "Let the technician assess the issue. The amount will be credited to the total invoice"
  },
  {
    "name": "CONVENTIONAL ELECTRICAL SWITCH REPLACEMENT",
    "category": "Electrical",
    "subCategory": "Switch and power outlets",
    "materialIncluded": false,
    "description": "Light bulbs not included"
  },
  {
    "name": "NEW POWER OUTLET INSTALLATION",
    "category": "Electrical",
    "subCategory": "Switch and power outlets",
    "materialIncluded": false,
    "description": "Light fixture not included"
  },
  {
    "name": "SHORT CIRCUIT",
    "category": "Electrical",
    "subCategory": "Switch and power outlets",
    "materialIncluded": false,
    "description": "Switch not included"
  },
  {
    "name": "POWER OUTLET RAPER",
    "category": "Electrical",
    "subCategory": "Switch and power outlets",
    "materialIncluded": false,
    "description":
        "Let the technician assess the issue. The amount will be credited to the total invoice"
  },
  {
    "name": "POWER OUTLET REPLACEMENT",
    "category": "Electrical",
    "subCategory": "Switch and power outlets",
    "materialIncluded": false,
    "description":
        "Let the technician assess the issue. The amount will be credited to the total invoice"
  },
  // Handy Man
  {
    "name": "REQUEST ASSESSMENT",
    "category": "Handy Man",
    "subCategory": "Partition building",
    "materialIncluded": false,
    "description":
        "Let the technician assess the issue.The amount will be credited to the total invoice"
  },

  // {
  //   "name": "5 PARTITIONS",
  //   "category": "Handy Man",
  //   "subCategory": "Partition building",
  //   "materialIncluded": false,
  //   "description": ""
  // },
  // {
  //   "name": "6 PARTITIONS",
  //   "category": "Handy Man",
  //   "subCategory": "Partition building",
  //   "materialIncluded": false,
  //   "description": ""
  // },
  // {
  //   "name": "7 PARTITIONS",
  //   "category": "Handy Man",
  //   "subCategory": "Partition building",
  //   "materialIncluded": false,
  //   "description": ""
  // },
  // {
  //   "name": "8 PARTITIONS",
  //   "category": "Handy Man",
  //   "subCategory": "Partition building",
  //   "materialIncluded": false,
  //   "description": ""
  // },
  // {
  //   "name": "9 PARTITIONS",
  //   "category": "Handy Man",
  //   "subCategory": "Partition building",
  //   "materialIncluded": false,
  //   "description": ""
  // },
  // {
  //   "name": "10  PARTITIONS",
  //   "category": "Handy Man",
  //   "subCategory": "Partition building",
  //   "materialIncluded": false,
  //   "description": ""
  // },
  {
    "name": "REQUEST ASSESSMENT",
    "category": "Handy Man",
    "subCategory": "Locksmith",
    "materialIncluded": false,
    "description":
        "Let the technician assess the issue.The amount will be credited to the total invoice"
  },
  {
    "name": "DOOR HANDEL REPLACEMENT",
    "category": "Handy Man",
    "subCategory": "Locksmith",
    "materialIncluded": false,
    "description":
        "Let the technician assess the issue. The amount will be credited to the total invoice"
  },
  {
    "name": "DOOR LOCK REPLACEMENT",
    "category": "Handy Man",
    "subCategory": "Locksmith",
    "materialIncluded": false,
    "description": ""
  },
  // Painting
  {
    "name": "Studio",
    "category": "Painting",
    "subCategory": "Studio",
    "materialIncluded": false,
    "description": ""
  },
  {
    "name": "Partition",
    "category": "Painting",
    "subCategory": "Partition",
    "materialIncluded": false,
    "description": ""
  },
  {
    "name": "Room",
    "category": "Painting",
    "subCategory": "Room",
    "materialIncluded": false,
    "description": ""
  },
  {
    "name": "House",
    "category": "Painting",
    "subCategory": "House",
    "materialIncluded": false,
    "description": ""
  },
  // Plumbing
  {
    "name": "REQUEST ASSESSMENT",
    "category": "Plumbing",
    "subCategory": "Sink",
    "materialIncluded": false,
    "description":
        "Let the technician assess the issue.The amount will be credited to the total invoice"
  },
  {
    "name": "SINK ACCESSORY INSTALLATION",
    "category": "Plumbing",
    "subCategory": "Sink",
    "materialIncluded": false,
    "description": ""
  },
  {
    "name": "SINK COMPONENT INSTALLATION",
    "category": "Plumbing",
    "subCategory": "Sink",
    "materialIncluded": false,
    "description": ""
  },
  {
    "name": "SINK MIXER INSTALLATION",
    "category": "Plumbing",
    "subCategory": "Sink",
    "materialIncluded": false,
    "description": ""
  },
  {
    "name": "REQUEST ASSESSMENT",
    "category": "Plumbing",
    "subCategory": "Shower",
    "materialIncluded": false,
    "description":
        "Let the technician assess the issue.The amount will be credited to the total invoice"
  },
  {
    "name": "SHOWER DOOR REPAIR",
    "category": "Plumbing",
    "subCategory": "Shower",
    "materialIncluded": false,
    "description":
        "Let the technician assess the issue. The amount will be credited to the total invoice"
  },
  {
    "name": "SHOWER STAND INSTALLATION",
    "category": "Plumbing",
    "subCategory": "Shower",
    "materialIncluded": false,
    "description": ""
  },
  {
    "name": "SHOWER MIXER INSTALLATION",
    "category": "Plumbing",
    "subCategory": "Shower",
    "materialIncluded": false,
    "description": ""
  },
  {
    "name": "VALVE REPLACEMENT",
    "category": "Plumbing",
    "subCategory": "Shower",
    "materialIncluded": false,
    "description": ""
  },
  {
    "name": "REQUEST ASSESSMENT",
    "category": "Plumbing",
    "subCategory": "Toilet",
    "materialIncluded": false,
    "description":
        "Let the technician assess the issue. The amount will be credited to the total invoice"
  },
  {
    "name": "FLOAT LEVER REPLACEMENT",
    "category": "Plumbing",
    "subCategory": "Toilet",
    "materialIncluded": false,
    "description": ""
  },
  {
    "name": "TOILET COVER INSTALLATION OR REPLACEMENT",
    "category": "Plumbing",
    "subCategory": "Toilet",
    "materialIncluded": false,
    "description": ""
  },
  {
    "name": "TOILET FLUSH REPAIR",
    "category": "Plumbing",
    "subCategory": "Toilet",
    "materialIncluded": false,
    "description": ""
  },
  {
    "name": "TOILET LEAK REPAIR",
    "category": "Plumbing",
    "subCategory": "Toilet",
    "materialIncluded": false,
    "description":
        "Let the technician assess the issue. The amount will be credited to the total invoice"
  },
  {
    "name": "REQUEST ASSESSMENT",
    "category": "Plumbing",
    "subCategory": "Boiler",
    "materialIncluded": false,
    "description":
        "Let the technician assess the issue. The amount will be credited to the total invoice"
  },
  {
    "name": "CENTRAL WATER HEATER",
    "category": "Plumbing",
    "subCategory": "Boiler",
    "materialIncluded": false,
    "description": "Water heater not included"
  },
  {
    "name": "CONVENTIONAL WATER HATER REPLACEMENT",
    "category": "Plumbing",
    "subCategory": "Boiler",
    "materialIncluded": false,
    "description": "Water heater not included"
  },
  {
    "name": "REQUEST ASSESSMENT",
    "category": "Plumbing",
    "subCategory": "Clogged Drains",
    "materialIncluded": false,
    "description":
        "Let the technician assess the issue. The amount will be credited to the total invoice"
  },
  {
    "name": "AIR & WATER PRESSURE MACHINE",
    "category": "Plumbing",
    "subCategory": "Clogged Drains",
    "materialIncluded": false,
    "description": "The machine clears all types of clogs"
  },
  {
    "name": "DRAIN JACK UNCLOGGING",
    "category": "Plumbing",
    "subCategory": "Clogged Drains",
    "materialIncluded": false,
    "description":
        "This alternative unclogging technique involves a metal drain jack that winds through pipes "
  },
  {
    "name": "SMALL MANHOLE",
    "category": "Plumbing",
    "subCategory": "Clogged Drains",
    "materialIncluded": false,
    "description": "Clearing an 80 * 100 cm manhole"
  }
];
