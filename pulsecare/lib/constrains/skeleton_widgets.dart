import 'package:flutter/material.dart';

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 12,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE6EBF5),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class AppointmentCardSkeleton extends StatelessWidget {
  const AppointmentCardSkeleton({super.key, this.dualActions = true});

  final bool dualActions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 92, height: 112, radius: 10),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 96, height: 24, radius: 30),
                        SizedBox(height: 10),
                        SkeletonBox(height: 20, radius: 8),
                        SizedBox(height: 8),
                        SkeletonBox(width: 120, height: 16, radius: 8),
                        SizedBox(height: 14),
                        SkeletonBox(height: 16, radius: 8),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (dualActions)
                const Row(
                  children: [
                    Expanded(child: SkeletonBox(height: 50, radius: 30)),
                    SizedBox(width: 10),
                    Expanded(child: SkeletonBox(height: 50, radius: 30)),
                  ],
                )
              else
                const SkeletonBox(height: 50, radius: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class DoctorRecommendationCardSkeleton extends StatelessWidget {
  const DoctorRecommendationCardSkeleton({super.key, this.topPadding = 16});

  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding, left: 16, right: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: const [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 92, height: 112, radius: 10),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(height: 20, radius: 8),
                        SizedBox(height: 8),
                        SkeletonBox(width: 120, height: 16, radius: 8),
                        SizedBox(height: 12),
                        SkeletonBox(width: 160, height: 14, radius: 8),
                        SizedBox(height: 10),
                        SkeletonBox(width: 130, height: 16, radius: 8),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14),
              SkeletonBox(height: 50, radius: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class ReportCardSkeleton extends StatelessWidget {
  const ReportCardSkeleton({super.key, this.topPadding = 16});

  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: topPadding, bottom: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(3, 3),
            ),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              SkeletonBox(width: 50, height: 50, radius: 10),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 18, radius: 8),
                    SizedBox(height: 8),
                    SkeletonBox(width: 170, height: 14, radius: 8),
                  ],
                ),
              ),
              SizedBox(width: 10),
              SkeletonBox(width: 18, height: 18, radius: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileScreenSkeleton extends StatelessWidget {
  const ProfileScreenSkeleton({super.key, this.title = 'My Profile'});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 85,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        elevation: 0.3,
        centerTitle: true,
        title: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        shadowColor: Colors.black,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 34, left: 16, right: 16, bottom: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 100, height: 100, radius: 50),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(height: 22, radius: 8),
                        SizedBox(height: 8),
                        SkeletonBox(width: 180, height: 14, radius: 8),
                        SizedBox(height: 12),
                        SkeletonBox(width: 100, height: 30, radius: 15),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _profileSkeletonCard(),
            _profileSkeletonCard(),
          ],
        ),
      ),
    );
  }

  static Widget _profileSkeletonCard() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(3, 3),
            ),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 180, height: 18, radius: 8),
              SizedBox(height: 18),
              SkeletonBox(height: 52, radius: 12),
              SizedBox(height: 14),
              SkeletonBox(height: 52, radius: 12),
              SizedBox(height: 14),
              SkeletonBox(height: 52, radius: 12),
            ],
          ),
        ),
      ),
    );
  }
}
