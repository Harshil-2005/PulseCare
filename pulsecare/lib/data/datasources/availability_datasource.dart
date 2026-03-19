import 'package:pulsecare/model/doctor_availability.dart';
import 'package:pulsecare/config/app_environment.dart';

abstract class AvailabilityDataSource {
  List<TimeSlot> getDefaultMorningSlots();
  List<TimeSlot> getDefaultAfternoonSlots();
}

class ProductionAvailabilityDataSource implements AvailabilityDataSource {
  @override
  List<TimeSlot> getDefaultMorningSlots() => const [];

  @override
  List<TimeSlot> getDefaultAfternoonSlots() => const [];
}

class LocalAvailabilityDataSource implements AvailabilityDataSource {
  LocalAvailabilityDataSource() {
    if (AppEnvironment.isProduction) {
      throw StateError(
        'LocalAvailabilityDataSource is disabled in production',
      );
    }
  }

  @override
  List<TimeSlot> getDefaultMorningSlots() {
    return [
      TimeSlot(time: '09:00 AM', status: SlotStatus.available),
      TimeSlot(time: '09:30 AM', status: SlotStatus.available),
      TimeSlot(time: '10:00 AM', status: SlotStatus.available),
      TimeSlot(time: '11:00 AM', status: SlotStatus.available),
      TimeSlot(time: '11:30 AM', status: SlotStatus.available),
    ];
  }

  @override
  List<TimeSlot> getDefaultAfternoonSlots() {
    return [
      TimeSlot(time: '02:00 PM', status: SlotStatus.available),
      TimeSlot(time: '03:30 PM', status: SlotStatus.available),
      TimeSlot(time: '04:00 PM', status: SlotStatus.available),
    ];
  }
}
