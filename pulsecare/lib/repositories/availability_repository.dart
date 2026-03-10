import 'package:pulsecare/data/datasources/availability_datasource.dart';
import 'package:pulsecare/domain/availability_engine.dart';
import 'package:pulsecare/model/appointment_model.dart';
import 'package:pulsecare/model/doctor_availability.dart';
import 'package:pulsecare/model/doctor_model.dart';

class AvailabilityRepository {
  AvailabilityRepository([
    AvailabilityDataSource? dataSource,
    AvailabilityEngine? engine,
  ]) : _dataSource = dataSource ?? LocalAvailabilityDataSource(),
       _engine = engine ?? AvailabilityEngine();

  final AvailabilityDataSource _dataSource;
  final AvailabilityEngine _engine;

  List<TimeSlot> getDefaultMorningSlots() {
    return _dataSource.getDefaultMorningSlots();
  }

  List<TimeSlot> getDefaultAfternoonSlots() {
    return _dataSource.getDefaultAfternoonSlots();
  }

  AvailabilitySlotsResult getSlots({
    required Doctor doctor,
    required DateTime date,
    required List<DateTime> bookedSlotDateTimes,
  }) {
    final appointments = bookedSlotDateTimes
        .map(
          (slotDateTime) => Appointment(
            doctor: doctor,
            doctorId: doctor.id,
            patientName: '',
            age: 0,
            gender: '',
            scheduledAt: slotDateTime,
            status: AppointmentStatus.confirmed,
          ),
        )
        .toList(growable: false);

    final generated = _engine.generateSlots(
      doctor: doctor,
      date: date,
      appointments: appointments,
    );

    final morningSlots = generated
        .where((slot) => slot['period'] == 'morning')
        .map(
          (slot) => TimeSlot(
            time: slot['time'] as String,
            status: slot['status'] as SlotStatus,
          ),
        )
        .toList(growable: false);

    final afternoonSlots = generated
        .where((slot) => slot['period'] == 'afternoon')
        .map(
          (slot) => TimeSlot(
            time: slot['time'] as String,
            status: slot['status'] as SlotStatus,
          ),
        )
        .toList(growable: false);

    return AvailabilitySlotsResult(
      isAvailable: generated.isNotEmpty,
      morningSlots: morningSlots,
      afternoonSlots: afternoonSlots,
    );
  }
}
