import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pulsecare/constrains/primary_icon_button.dart';
import 'package:pulsecare/model/day_schedule.dart';
import 'package:pulsecare/model/doctor_model.dart';
import 'package:pulsecare/user/patient_detail_screen.dart';
import '../providers/repository_providers.dart';

final _doctorDetailUserProvider = StreamProvider.autoDispose.family((
  ref,
  String userId,
) {
  return ref.read(userRepositoryProvider).watchUserById(userId);
});

class DoctorDetailScreen extends ConsumerStatefulWidget {
  final String doctorId;
  final String? aiSummaryId;

  const DoctorDetailScreen({
    super.key,
    required this.doctorId,
    this.aiSummaryId,
  });

  @override
  ConsumerState<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends ConsumerState<DoctorDetailScreen> {
  bool isSelected = false;
  late Doctor? doctor;
  bool _ready = false;

  String _fullDayName(String day) {
    switch (day) {
      case 'Mon':
        return 'Monday';
      case 'Tue':
        return 'Tuesday';
      case 'Wed':
        return 'Wednesday';
      case 'Thu':
        return 'Thursday';
      case 'Fri':
        return 'Friday';
      case 'Sat':
        return 'Saturday';
      case 'Sun':
        return 'Sunday';
      default:
        return day;
    }
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    doctor = await ref
        .read(doctorRepositoryProvider)
        .getDoctorById(widget.doctorId);
    if (!mounted) return;
    setState(() {
      _ready = true;
    });
  }

  List<String> _scheduleLines(DaySchedule schedule) {
    String line1 = '';
    String line2 = '';

    if (schedule.morningEnabled &&
        schedule.morningStart.isNotEmpty &&
        schedule.morningEnd.isNotEmpty) {
      line1 = '${schedule.morningStart} - ${schedule.morningEnd}';
    }
    if (schedule.afternoonEnabled &&
        schedule.afternoonStart.isNotEmpty &&
        schedule.afternoonEnd.isNotEmpty) {
      line2 = '${schedule.afternoonStart} - ${schedule.afternoonEnd}';
    }

    if (line1.isEmpty && line2.isEmpty) {
      line2 = 'OFF';
    }

    return <String>[line1, line2];
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final currentDoctor = doctor;
    if (currentDoctor == null) {
      return Scaffold(
        appBar: AppBar(
          leadingWidth: 40,
          titleSpacing: 0,
          toolbarHeight: 85,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          elevation: 0.3,
          title: Row(
            children: [
              Spacer(),
              Text(
                'Doctor Details',
                style: TextStyle(fontSize: 20, fontWeight: .w600),
              ),
              Spacer(),
              SvgPicture.asset('assets/icons/like.svg', height: 18, width: 20),
              SizedBox(width: 20, height: 18),
            ],
          ),
          shadowColor: Colors.black,
          automaticallyImplyLeading: true,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: SvgPicture.asset(
              'assets/icons/backarrow.svg',
              width: 24,
              height: 20,
            ),
          ),
        ),
        body: const SizedBox.shrink(),
      );
    }
    final doctorUser = currentDoctor.userId.isEmpty
        ? null
        : ref
              .watch(_doctorDetailUserProvider(currentDoctor.userId))
              .valueOrNull;
    final doctorPhone = doctorUser?.phone ?? '';

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 40,
        titleSpacing: 0,
        toolbarHeight: 85,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        elevation: 0.3,
        title: Row(
          children: [
            Spacer(),
            Text(
              'Doctor Details',
              style: TextStyle(fontSize: 20, fontWeight: .w600),
            ),
            Spacer(),
            SvgPicture.asset('assets/icons/like.svg', height: 18, width: 20),
            SizedBox(width: 20, height: 18),
          ],
        ),
        shadowColor: Colors.black,
        automaticallyImplyLeading: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: SvgPicture.asset(
            'assets/icons/backarrow.svg',
            width: 24,
            height: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              child: Padding(
                padding: const EdgeInsets.only(top: 24, left: 8, right: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        image: DecorationImage(
                          image: AssetImage(currentDoctor.image),
                          fit: BoxFit.cover,
                        ),
                      ),
                      height: 140,
                      width: 120,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              currentDoctor.name,
                              style: TextStyle(fontSize: 20, fontWeight: .w700),
                            ),

                            Text(
                              currentDoctor.speciality,

                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: .w500,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 14),
                            Row(
                              children: [
                                SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: SvgPicture.asset(
                                    'assets/icons/call.svg',
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  doctorPhone,

                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: .w400,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: SvgPicture.asset(
                                    'assets/icons/location.svg',
                                  ),
                                ),
                                SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    currentDoctor.address,
                                    style: TextStyle(fontSize: 14),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                SizedBox(width: 10),
                                Align(
                                  alignment: AlignmentGeometry.bottomRight,
                                  child: Container(
                                    width: 72,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      color: Color.fromARGB(255, 228, 233, 251),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 10,
                                          height: 10,
                                          child: Center(
                                            child: SvgPicture.asset(
                                              'assets/icons/map.svg',
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'View Map',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: .w400,
                                            color: Color(0xff3F67FD),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Divider(height: 2),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 8.0;
                  final itemWidth = ((constraints.maxWidth - gap * 3) / 4)
                      .clamp(70.0, 85.0);
                  return Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 10,
                              color: const Color.fromARGB(255, 219, 219, 219),
                            ),
                          ],
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        height: 85,
                        width: itemWidth,
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/images/persons.png',
                              color: Color(0xff3F67FD),
                              width: 40,
                              height: 40,
                            ),
                            SizedBox(height: 5),
                            Text(
                              '${currentDoctor.patients}+',
                              style: TextStyle(fontWeight: .w500),
                            ),
                            Text(
                              'Patients',
                              style: TextStyle(
                                color: Color(0xff3F67FD),
                                fontSize: 12,
                                fontWeight: .w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: gap),
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 10,
                              color: const Color.fromARGB(255, 219, 219, 219),
                            ),
                          ],
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        height: 85,
                        width: itemWidth,
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/images/expereance.png',
                              color: Color(0xff3F67FD),
                              width: 40,
                              height: 40,
                            ),
                            SizedBox(height: 5),
                            Text(
                              '${currentDoctor.experience}+',
                              style: TextStyle(fontWeight: .w500),
                            ),
                            Text(
                              'Years Exp.',
                              style: TextStyle(
                                color: Color(0xff3F67FD),
                                fontSize: 12,
                                fontWeight: .w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: gap),
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 10,
                              color: const Color.fromARGB(255, 219, 219, 219),
                            ),
                          ],
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        height: 85,
                        width: itemWidth,
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/images/rating.png',
                              color: Color(0xff3F67FD),
                              width: 40,
                              height: 40,
                            ),
                            SizedBox(height: 5),
                            Text(
                              currentDoctor.rating.toStringAsFixed(1),
                              style: TextStyle(fontWeight: .w500),
                            ),
                            Text(
                              'Rating',
                              style: TextStyle(
                                color: Color(0xff3F67FD),
                                fontSize: 12,
                                fontWeight: .w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: gap),
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 10,
                              color: const Color.fromARGB(255, 219, 219, 219),
                            ),
                          ],
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        height: 85,
                        width: itemWidth,
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/images/reviews.png',
                              color: Color(0xff3F67FD),
                              width: 40,
                              height: 40,
                            ),
                            SizedBox(height: 5),
                            Text(
                              '${currentDoctor.reviews}',
                              style: TextStyle(fontWeight: .w500),
                            ),
                            Text(
                              'Reviews',
                              style: TextStyle(
                                color: Color(0xff3F67FD),
                                fontSize: 12,
                                fontWeight: .w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 32, right: 16, left: 16),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xff3F67FD)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 25,
                            height: 25,
                            child: Image.asset(
                              'assets/images/doctor.png',
                              color: Color(0xff3F67FD),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'About',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        currentDoctor.about,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 16),
              child: Text(
                'Working Hours',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: .w500,
                ),
              ),
            ),
            Column(
              children: List.generate(currentDoctor.schedule.length, (index) {
                final schedule = currentDoctor.schedule[index];
                final lines = _scheduleLines(schedule);
                final hasTwoSlots =
                    lines[0].isNotEmpty &&
                    lines[1].isNotEmpty &&
                    lines[1] != 'OFF';
                const rowHeight = 56.0;
                const lineHeight = 24.0;
                final singleLineText = lines.firstWhere(
                  (text) => text.isNotEmpty,
                  orElse: () => '',
                );
                final isOffText = singleLineText == 'OFF';
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 1,
                        horizontal: 16,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              height: rowHeight,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _fullDayName(schedule.day),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: SizedBox(
                              height: rowHeight,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: SizedBox(
                                  width: 160,
                                  child: hasTwoSlots
                                      ? Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: List.generate(2, (index) {
                                            final text = lines[index];
                                            return SizedBox(
                                              height: lineHeight,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  text,
                                                  maxLines: 1,
                                                  softWrap: false,
                                                  overflow:
                                                      TextOverflow.visible,
                                                  textAlign: TextAlign.left,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        )
                                      : Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            singleLineText,
                                            maxLines: 1,
                                            softWrap: false,
                                            overflow: TextOverflow.visible,
                                            textAlign: TextAlign.left,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: isOffText
                                                  ? Colors.red.shade400
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (index != currentDoctor.schedule.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(
                          height: 1,
                          thickness: 0.8,
                          color: Colors.grey.shade300,
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),

            Padding(
              padding: const EdgeInsets.only(
                top: 8,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: PrimaryIconButton(
                text: 'Book Appointment',
                iconPath: 'assets/images/chat.png',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PatientDetailScreen(
                        doctor: currentDoctor,
                        aiSummaryId: widget.aiSummaryId,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
