// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'campaign_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CampaignAdapter extends TypeAdapter<Campaign> {
  @override
  final int typeId = 0;

  @override
  Campaign read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Campaign(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      organization: fields[3] as Organization,
      category: fields[4] as String,
      targetAmount: fields[5] as double,
      currentAmount: fields[6] as double,
      startDate: fields[7] as DateTime,
      endDate: fields[8] as DateTime,
      status: fields[9] as String,
      isFeatured: fields[10] as bool,
      tags: (fields[11] as List).cast<String>(),
      images: (fields[12] as List).cast<String>(),
      updates: (fields[13] as List).cast<CampaignUpdate>(),
      faqs: (fields[14] as List).cast<FAQ>(),
      createdAt: fields[15] as DateTime,
      updatedAt: fields[16] as DateTime,
      progress: fields[17] as double,
      isActive: fields[18] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Campaign obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.organization)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.targetAmount)
      ..writeByte(6)
      ..write(obj.currentAmount)
      ..writeByte(7)
      ..write(obj.startDate)
      ..writeByte(8)
      ..write(obj.endDate)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.isFeatured)
      ..writeByte(11)
      ..write(obj.tags)
      ..writeByte(12)
      ..write(obj.images)
      ..writeByte(13)
      ..write(obj.updates)
      ..writeByte(14)
      ..write(obj.faqs)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.updatedAt)
      ..writeByte(17)
      ..write(obj.progress)
      ..writeByte(18)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CampaignAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OrganizationAdapter extends TypeAdapter<Organization> {
  @override
  final int typeId = 1;

  @override
  Organization read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Organization(
      id: fields[0] as String,
      organizationName: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Organization obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.organizationName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CampaignUpdateAdapter extends TypeAdapter<CampaignUpdate> {
  @override
  final int typeId = 2;

  @override
  CampaignUpdate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CampaignUpdate(
      title: fields[0] as String,
      description: fields[1] as String,
      date: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CampaignUpdate obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CampaignUpdateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FAQAdapter extends TypeAdapter<FAQ> {
  @override
  final int typeId = 3;

  @override
  FAQ read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FAQ(
      question: fields[0] as String,
      answer: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FAQ obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.question)
      ..writeByte(1)
      ..write(obj.answer);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FAQAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
