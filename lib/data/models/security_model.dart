// lib/data/models/security_model.dart

import 'package:floor/floor.dart';

@Entity(tableName: 'visitor_logs')
class VisitorLogModel {
  @PrimaryKey()
  final String id;
  @ColumnInfo(name: 'visitor_name')
  final String visitorName;
  @ColumnInfo(name: 'id_number')
  final String idNumber;
  final String purpose;             // e.g. "Meeting Principal", "Delivery"
  @ColumnInfo(name: 'whom_to_see')
  final String whomToSee;
  @ColumnInfo(name: 'check_in_time')
  final int checkInTime;            // Unix epoch ms
  @ColumnInfo(name: 'check_out_time')
  final int? checkOutTime;
  @ColumnInfo(name: 'vehicle_reg')
  final String? vehicleReg;
  @ColumnInfo(name: 'recorded_by')
  final String recordedBy;          // Security Officer ID

  const VisitorLogModel({
    required this.id,
    required this.visitorName,
    required this.idNumber,
    required this.purpose,
    required this.whomToSee,
    required this.checkInTime,
    this.checkOutTime,
    this.vehicleReg,
    required this.recordedBy,
  });
}
