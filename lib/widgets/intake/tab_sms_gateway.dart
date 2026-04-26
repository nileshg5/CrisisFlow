import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/mock_data.dart';
import '../shared/glass_card.dart';

class TabSmsGateway extends StatelessWidget {
  const TabSmsGateway({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Incoming Messages
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Live SMS & WhatsApp Ingestion', style: AppTextStyles.h3()),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: mockSmsMessages.length,
                  separatorBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: Colors.white10),
                  ),
                  itemBuilder: (context, index) {
                    final msg = mockSmsMessages[index];
                    return _buildMessageRow(msg);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        
        // Manual Input & Parser
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Manual Syntax Ingestion', style: AppTextStyles.h3()),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      maxLines: 4,
                      style: AppTextStyles.technical(),
                      decoration: InputDecoration(
                        hintText: 'NEED:medical,location:Dharavi,count:40,notes:insulin shortage',
                        hintStyle: AppTextStyles.technical(color: AppColors.outline),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {},
                        child: Text('PARSE TO DATABASE', style: AppTextStyles.labelCaps().copyWith(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageRow(Map<String, dynamic> msg) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40, height: 40,
          decoration: const BoxDecoration(color: AppColors.surfaceVariant, shape: BoxShape.circle),
          child: const Icon(Icons.phone_android, size: 20, color: AppColors.outline),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(msg['phone'], style: AppTextStyles.technical()),
                  Text(msg['timeAgo'], style: AppTextStyles.technical(color: AppColors.outline)),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Text(msg['message'], style: AppTextStyles.technical().copyWith(height: 1.5)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
