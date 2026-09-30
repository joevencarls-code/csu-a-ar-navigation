import 'package:flutter/material.dart';
import '../../models/campus_models.dart';
import '../../services/campus_repository.dart';
import 'admin_crud_screen.dart';

class RoomsAdminScreen extends CrudScreen<Room> {
  RoomsAdminScreen({super.key, bool showBackButton = true}) : super(
          showBackButton: showBackButton,
          title: 'Manage Rooms',
          icon: Icons.meeting_room_rounded,
          fields: [
            CrudField(
              key: 'building_id',
              label: 'Building',
              type: CrudFieldType.reference,
              required: true,
              loadOptions: () async {
                final buildings = await CampusRepository().getBuildings();
                return buildings
                    .map((b) => CrudReferenceOption(b.id, b.name))
                    .toList();
              },
            ),
            const CrudField(key: 'room_name', label: 'Room Name', type: CrudFieldType.text, required: true),
            const CrudField(key: 'room_type', label: 'Room Type', type: CrudFieldType.text),
            const CrudField(key: 'floor', label: 'Floor', type: CrudFieldType.integer),
            const CrudField(key: 'description', label: 'Description', type: CrudFieldType.multiline),
          ],
          fetchAll: CampusRepository().getAllRooms,
          onCreate: CampusRepository().createRoom,
          onUpdate: CampusRepository().updateRoom,
          onDelete: CampusRepository().deleteRoom,
          idOf: (r) => r.id,
          titleOf: (r) => r.roomName,
          subtitleOf: (r) => [
            if (r.roomType != null) r.roomType,
            if (r.floor != null) 'Floor ${r.floor}',
          ].join(' • '),
          valuesOf: (r) => {
            'building_id': r.buildingId,
            'room_name': r.roomName,
            'room_type': r.roomType,
            'floor': r.floor,
            'description': r.description,
          },
        );
}
