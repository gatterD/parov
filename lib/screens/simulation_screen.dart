import 'package:flutter/material.dart';

import '../models/steam_simulation.dart';
import '../theme/app_theme.dart';
import '../widgets/simulation_controls.dart';
import '../widgets/status_tag.dart';
import '../widgets/system_overview.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  late final SteamSimulation _simulation = SteamSimulation();

  @override
  void dispose() {
    _simulation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _simulation,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                final overview = SystemOverview(simulation: _simulation);
                final controls = SimulationControls(simulation: _simulation);
                return Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: overview),
                                SizedBox(width: 350, child: controls),
                              ],
                            )
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              children: [
                                SizedBox(height: 680, child: overview),
                                const SizedBox(height: 16),
                                controls,
                              ],
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 16 : 24,
            compact ? 10 : 18,
            compact ? 16 : 24,
            compact ? 10 : 18,
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 34 : 38,
                height: compact ? 34 : 38,
                decoration: BoxDecoration(
                  color: AppColors.steam.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.device_thermostat, color: AppColors.steam),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ПАРОВОЕ ОТОПЛЕНИЕ',
                      style: TextStyle(
                        fontSize: compact ? 13 : 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: compact ? .4 : 1.1,
                      ),
                    ),
                    if (!compact) ...[
                      SizedBox(height: 3),
                      Text(
                        'Однопроводная система · вариант 6',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              StatusTag(
                label: _simulation.isRunning ? 'СИМУЛЯЦИЯ' : 'ОЖИДАНИЕ',
                color:
                    _simulation.isRunning ? AppColors.water : AppColors.muted,
              ),
            ],
          ),
        );
      },
    );
  }
}
