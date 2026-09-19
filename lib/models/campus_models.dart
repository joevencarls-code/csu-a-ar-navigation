class Building {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? location;
  final String? offices;
  final String? dean;

  Building({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.location,
    this.offices,
    this.dean,
  });

  factory Building.fromJson(Map<String, dynamic> json) {
    return Building(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      location: json['location'] as String?,
      offices: json['offices'] as String?,
      dean: json['dean'] as String?,
    );
  }
}

class Room {
  final int id;
  final int buildingId;
  final String roomName;
  final String? roomType;
  final int? floor;
  final String? description;

  Room({
    required this.id,
    required this.buildingId,
    required this.roomName,
    this.roomType,
    this.floor,
    this.description,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as int,
      buildingId: json['building_id'] as int,
      roomName: json['room_name'] as String,
      roomType: json['room_type'] as String?,
      floor: json['floor'] as int?,
      description: json['description'] as String?,
    );
  }
}

class FacultyMember {
  final int id;
  final int? roomId;
  final int? collegeId;
  final String fullname;
  final String? position;
  final String? email;
  final String? imageUrl;

  FacultyMember({
    required this.id,
    this.roomId,
    this.collegeId,
    required this.fullname,
    this.position,
    this.email,
    this.imageUrl,
  });

  factory FacultyMember.fromJson(Map<String, dynamic> json) {
    return FacultyMember(
      id: json['id'] as int,
      roomId: json['room_id'] as int?,
      collegeId: json['college_id'] as int?,
      fullname: json['fullname'] as String,
      position: json['position'] as String?,
      email: json['email'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }
}

class QrCodeEntry {
  final int id;
  final int roomId;
  final String qrValue;

  QrCodeEntry({
    required this.id,
    required this.roomId,
    required this.qrValue,
  });

  factory QrCodeEntry.fromJson(Map<String, dynamic> json) {
    return QrCodeEntry(
      id: json['id'] as int,
      roomId: json['room_id'] as int,
      qrValue: json['qr_value'] as String,
    );
  }
}

class Waypoint {
  final int id;
  final String name;
  final double x;
  final double y;
  final int floor;

  Waypoint({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.floor,
  });

  factory Waypoint.fromJson(Map<String, dynamic> json) {
    return Waypoint(
      id: json['id'] as int,
      name: json['name'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      floor: json['floor'] as int,
    );
  }
}

class PathEdge {
  final int id;
  final int fromNode;
  final int toNode;
  final double distance;

  PathEdge({
    required this.id,
    required this.fromNode,
    required this.toNode,
    required this.distance,
  });

  factory PathEdge.fromJson(Map<String, dynamic> json) {
    return PathEdge(
      id: json['id'] as int,
      fromNode: json['from_node'] as int,
      toNode: json['to_node'] as int,
      distance: (json['distance'] as num).toDouble(),
    );
  }
}

class CampusSettings {
  final String campusName;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final String? executiveOfficer;
  final int? totalColleges;
  final int? totalPrograms;
  final int? totalFaculty;

  CampusSettings({
    required this.campusName,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.executiveOfficer,
    this.totalColleges,
    this.totalPrograms,
    this.totalFaculty,
  });

  factory CampusSettings.fromJson(Map<String, dynamic> json) {
    return CampusSettings(
      campusName: json['campus_name'] as String,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      executiveOfficer: json['executive_officer'] as String?,
      totalColleges: json['total_colleges'] as int?,
      totalPrograms: json['total_programs'] as int?,
      totalFaculty: json['total_faculty'] as int?,
    );
  }
}

class College {
  final int id;
  final String name;
  final String? abbrev;
  final String? dean;
  final String? programs;
  final String? location;
  final String? description;

  College({
    required this.id,
    required this.name,
    this.abbrev,
    this.dean,
    this.programs,
    this.location,
    this.description,
  });

  factory College.fromJson(Map<String, dynamic> json) {
    return College(
      id: json['id'] as int,
      name: json['name'] as String,
      abbrev: json['abbrev'] as String?,
      dean: json['dean'] as String?,
      programs: json['programs'] as String?,
      location: json['location'] as String?,
      description: json['description'] as String?,
    );
  }
}

class OfficeEntry {
  final int id;
  final String name;
  final String? abbreviation;
  final String? location;
  final String? head;
  final String? purpose;
  final String? contact;
  final String? imageUrl;

  OfficeEntry({
    required this.id,
    required this.name,
    this.abbreviation,
    this.location,
    this.head,
    this.purpose,
    this.contact,
    this.imageUrl,
  });

  factory OfficeEntry.fromJson(Map<String, dynamic> json) {
    return OfficeEntry(
      id: json['id'] as int,
      name: json['name'] as String,
      abbreviation: json['abbreviation'] as String?,
      location: json['location'] as String?,
      head: json['head'] as String?,
      purpose: json['purpose'] as String?,
      contact: json['contact'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }
}

class ServiceEntry {
  final int id;
  final String name;
  final String? description;

  ServiceEntry({required this.id, required this.name, this.description});

  factory ServiceEntry.fromJson(Map<String, dynamic> json) {
    return ServiceEntry(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }
}

class FaqEntry {
  final int id;
  final String question;
  final String? answer;

  FaqEntry({required this.id, required this.question, this.answer});

  factory FaqEntry.fromJson(Map<String, dynamic> json) {
    return FaqEntry(
      id: json['id'] as int,
      question: json['question'] as String,
      answer: json['answer'] as String?,
    );
  }
}

class LeadershipMember {
  final int id;
  final String name;
  final String? position;
  final String? department;
  final String? imagePath;
  final String? initials;

  LeadershipMember({
    required this.id,
    required this.name,
    this.position,
    this.department,
    this.imagePath,
    this.initials,
  });

  factory LeadershipMember.fromJson(Map<String, dynamic> json) {
    return LeadershipMember(
      id: json['id'] as int,
      name: json['name'] as String,
      position: json['position'] as String?,
      department: json['department'] as String?,
      imagePath: json['image_path'] as String?,
      initials: json['initials'] as String?,
    );
  }
}

class CollegeFacultyGroup {
  final int id;
  final String college;
  final String? faculty;
  final List<FacultyMember> members;

  CollegeFacultyGroup({
    required this.id,
    required this.college,
    this.faculty,
    this.members = const [],
  });

  factory CollegeFacultyGroup.fromJson(Map<String, dynamic> json) {
    return CollegeFacultyGroup(
      id: json['id'] as int,
      college: json['college'] as String,
      faculty: json['faculty'] as String?,
    );
  }
}
