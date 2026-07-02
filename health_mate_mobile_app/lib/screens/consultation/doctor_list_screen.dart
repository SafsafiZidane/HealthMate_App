import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/consultation_provider.dart';

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({super.key});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ConsultationProvider>(context, listen: false).fetchDoctors();
      Provider.of<ConsultationProvider>(context, listen: false).fetchMyConsultations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final consultationProvider = Provider.of<ConsultationProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Medical Consultation", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: const TabBar(
                labelColor: Color(0xFF0052CC),
                unselectedLabelColor: Color(0xFF64748B),
                indicatorColor: Color(0xFF0052CC),
                indicatorWeight: 3,
                tabs: [
                  Tab(text: "Available Doctors"),
                  Tab(text: "My Requests"),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildDoctorList(consultationProvider),
                  _buildMyConsultations(consultationProvider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorList(ConsultationProvider provider) {
    if (provider.isLoading) return const Center(child: CircularProgressIndicator());
    if (provider.doctors.isEmpty) return const Center(child: Text("No doctors available at the moment."));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.doctors.length,
      itemBuilder: (context, index) {
        final doctor = provider.doctors[index];
        final profile = doctor['doctor_profile'];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
          ),
          child: Row(
            children: [
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.person_rounded, size: 40, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Dr. ${doctor['first_name']} ${doctor['last_name']}", 
                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(profile != null ? profile['specialty'] : "General Practitioner", 
                         style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text("${profile != null ? profile['experience_years'] : '5'}+ years exp.", 
                             style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _showConsultationDialog(doctor['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0052CC),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text("Consult", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMyConsultations(ConsultationProvider provider) {
    if (provider.isLoading) return const Center(child: CircularProgressIndicator());
    if (provider.myConsultations.isEmpty) return const Center(child: Text("No consultation requests found."));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.myConsultations.length,
      itemBuilder: (context, index) {
        final item = provider.myConsultations[index];
        final bool hasReply = item['doctor_reply'] != null;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: hasReply ? const Color(0xFF0052CC).withOpacity(0.3) : const Color(0xFFE2E8F0)),
          ),
          child: ExpansionTile(
            leading: Icon(
              hasReply ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
              color: hasReply ? Colors.green : Colors.orange,
            ),
            title: Text(item['condition_description'], maxLines: 1, overflow: TextOverflow.ellipsis, 
                        style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text("Status: ${item['status']}"),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const Text("My description:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(item['condition_description']),
                    const SizedBox(height: 16),
                    const Text("Doctor's Reply:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(item['doctor_reply'] ?? "The doctor has not replied yet.", 
                         style: TextStyle(fontStyle: hasReply ? FontStyle.normal : FontStyle.italic, 
                                        color: hasReply ? const Color(0xFF0F172A) : Colors.grey)),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _showConsultationDialog(int doctorId) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Describe your condition"),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: "Enter symptoms, duration, etc.",
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final success = await Provider.of<ConsultationProvider>(context, listen: false)
                    .requestConsultation(doctorId, controller.text);
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Request sent successfully!"), backgroundColor: Colors.green),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0052CC), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text("Submit", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
