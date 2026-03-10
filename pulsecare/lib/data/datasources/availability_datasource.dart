import 'package:pulsecare/model/doctor_availability.dart';

abstract class AvailabilityDataSource {
  List<TimeSlot> getDefaultMorningSlots();
  List<TimeSlot> getDefaultAfternoonSlots();
}

class LocalAvailabilityDataSource implements AvailabilityDataSource {
  LocalAvailabilityDataSource();

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
