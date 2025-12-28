// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventAdapter extends TypeAdapter<Event> {
  @override
  final int typeId = 10;

  @override
  Event read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Event(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      category: fields[3] as String,
      eventType: fields[4] as String,
      location: fields[5] as EventLocation,
      startDate: fields[6] as DateTime,
      endDate: fields[7] as DateTime,
      images: (fields[8] as List).cast<EventImage>(),
      status: fields[9] as String,
      maxVolunteers: fields[10] as int,
      requiredSkills: (fields[11] as List).cast<String>(),
      eligibility: fields[12] as String,
      organizerType: fields[13] as String,
      organizer: fields[14] as EventOrganizer,
      volunteers: (fields[15] as List).cast<String>(),
      isFeatured: fields[16] as bool,
      tags: (fields[17] as List).cast<String>(),
      createdAt: fields[18] as DateTime,
      updatedAt: fields[19] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Event obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.eventType)
      ..writeByte(5)
      ..write(obj.location)
      ..writeByte(6)
      ..write(obj.startDate)
      ..writeByte(7)
      ..write(obj.endDate)
      ..writeByte(8)
      ..write(obj.images)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.maxVolunteers)
      ..writeByte(11)
      ..write(obj.requiredSkills)
      ..writeByte(12)
      ..write(obj.eligibility)
      ..writeByte(13)
      ..write(obj.organizerType)
      ..writeByte(14)
      ..write(obj.organizer)
      ..writeByte(15)
      ..write(obj.volunteers)
      ..writeByte(16)
      ..write(obj.isFeatured)
      ..writeByte(17)
      ..write(obj.tags)
      ..writeByte(18)
      ..write(obj.createdAt)
      ..writeByte(19)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EventLocationAdapter extends TypeAdapter<EventLocation> {
  @override
  final int typeId = 11;

  @override
  EventLocation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EventLocation(
      address: fields[0] as String,
      city: fields[1] as String,
      state: fields[2] as String,
      coordinates: fields[3] as EventCoordinates,
    );
  }

  @override
  void write(BinaryWriter writer, EventLocation obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.address)
      ..writeByte(1)
      ..write(obj.city)
      ..writeByte(2)
      ..write(obj.state)
      ..writeByte(3)
      ..write(obj.coordinates);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventLocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EventCoordinatesAdapter extends TypeAdapter<EventCoordinates> {
  @override
  final int typeId = 12;

  @override
  EventCoordinates read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EventCoordinates(
      type: fields[0] as String,
      coordinates: (fields[1] as List).cast<double>(),
    );
  }

  @override
  void write(BinaryWriter writer, EventCoordinates obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.coordinates);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventCoordinatesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EventImageAdapter extends TypeAdapter<EventImage> {
  @override
  final int typeId = 13;

  @override
  EventImage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EventImage(
      url: fields[0] as String,
      publicId: fields[1] as String,
      isPrimary: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, EventImage obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.publicId)
      ..writeByte(2)
      ..write(obj.isPrimary);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventImageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EventOrganizerAdapter extends TypeAdapter<EventOrganizer> {
  @override
  final int typeId = 14;

  @override
  EventOrganizer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EventOrganizer(
      id: fields[0] as String,
      organizationName: fields[1] as String,
      officialEmail: fields[2] as String,
      logo: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EventOrganizer obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.organizationName)
      ..writeByte(2)
      ..write(obj.officialEmail)
      ..writeByte(3)
      ..write(obj.logo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventOrganizerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
