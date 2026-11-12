import 'package:flutter/material.dart';

import '../models/steam_simulation.dart';
import '../theme/app_theme.dart';

class SimulationControls extends StatelessWidget {
  const SimulationControls({super.key, required this.simulation});

  final SteamSimulation simulation;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: Colors.white10)),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Пульт управления',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
              Text(
                _formatTime(simulation.elapsedSeconds),
                style: const TextStyle(
                  color: AppColors.muted,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: simulation.toggle,
                  icon: Icon(
                      simulation.isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(simulation.isRunning ? 'Пауза' : 'Пуск'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.steam,
                    foregroundColor: const Color(0xFF18201F),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              IconButton.filledTonal(
                onPressed: simulation.reset,
                tooltip: 'Сбросить параметры',
                icon: const Icon(Icons.restart_alt),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceRaised,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(48, 48),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionLabel('ПАРОВОЙ КОТЁЛ'),
          _ParameterSlider(
            label: 'Производительность',
            value: simulation.boilerOutput,
            displayValue: '${simulation.boilerOutput.toStringAsFixed(0)}%',
            min: 20,
            max: 100,
            onChanged: simulation.setBoilerOutput,
          ),
          const SizedBox(height: 17),
          const _SectionLabel('АРМАТУРА И ОТОПЛЕНИЕ'),
          _ParameterSlider(
            label: 'Редукционный клапан · уставка',
            value: simulation.regulatorSetting,
            displayValue:
                '${simulation.regulatorSetting.toStringAsFixed(1)} бар',
            min: 1,
            max: 4.5,
            divisions: 35,
            onChanged: simulation.setRegulatorSetting,
          ),
          _ParameterSlider(
            label: 'Клапан 8 · подача в грелки',
            value: simulation.inletValve,
            displayValue: '${simulation.inletValve.toStringAsFixed(0)}%',
            min: 0,
            max: 100,
            onChanged: simulation.setInletValve,
          ),
          _ParameterSlider(
            label: 'Клапан 10 · выход из грелок',
            value: simulation.outletValve,
            displayValue: '${simulation.outletValve.toStringAsFixed(0)}%',
            min: 0,
            max: 100,
            onChanged: simulation.setOutletValve,
          ),
          _ParameterSlider(
            label: 'Клапан 13 · отвод конденсата',
            value: simulation.drainValve,
            displayValue: '${simulation.drainValve.toStringAsFixed(0)}%',
            min: 0,
            max: 100,
            onChanged: simulation.setDrainValve,
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(9),
            ),
            child: SwitchListTile.adaptive(
              value: simulation.reducerFailed,
              onChanged: simulation.setReducerFailed,
              activeTrackColor: AppColors.danger,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              title: const Text('Отказ редуктора',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: const Text('Проверка предохранительного клапана',
                  style: TextStyle(color: AppColors.muted, fontSize: 11)),
            ),
          ),
          const SizedBox(height: 16),
          _ReadoutRow(
            icon: Icons.air,
            label: 'Качество осушенного пара',
            value: '${simulation.steamQuality.toStringAsFixed(0)}%',
            color: AppColors.water,
          ),
          const SizedBox(height: 9),
          _ReadoutRow(
            icon: Icons.opacity,
            label: 'Уровень конденсата',
            value: '${(simulation.condensateLevel * 100).toStringAsFixed(0)}%',
            color: AppColors.water,
          ),
          if (simulation.safetyValveOpen) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.danger.withValues(alpha: .3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.danger, size: 18),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text('Сброс пара: давление котла выше 6 бар',
                        style:
                            TextStyle(color: AppColors.danger, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainder';
  }
}

class _ParameterSlider extends StatelessWidget {
  const _ParameterSlider({
    required this.label,
    required this.value,
    required this.displayValue,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
  });

  final String label;
  final double value;
  final String displayValue;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            ),
            const SizedBox(width: 8),
            Text(displayValue,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ReadoutRow extends StatelessWidget {
  const _ReadoutRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: const TextStyle(color: AppColors.muted, fontSize: 11)),
        ),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.steam,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    );
  }
}
