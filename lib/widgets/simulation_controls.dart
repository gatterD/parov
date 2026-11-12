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
            label: 'Мощность котла',
            value: simulation.boilerOutput,
            displayValue:
                '${simulation.boilerThermalPowerKw.toStringAsFixed(0)} кВт',
            description:
                'Нагрузка ${simulation.boilerOutput.toStringAsFixed(0)}% '
                'от номинала',
            min: 20,
            max: 100,
            onChanged: simulation.setBoilerOutput,
          ),
          const SizedBox(height: 17),
          const _SectionLabel('АРМАТУРА И ОТОПЛЕНИЕ'),
          _ParameterSlider(
            label: 'Редуктор · уставка выходного давления',
            value: simulation.regulatorSetting,
            displayValue:
                '${simulation.regulatorSetting.toStringAsFixed(1)} бар',
            description: 'Клапан поддерживает это давление после редуктора',
            min: 1,
            max: 4.5,
            divisions: 35,
            onChanged: simulation.setRegulatorSetting,
          ),
          _ParameterSlider(
            label: 'Клапан 8 · подача пара в грелки',
            value: simulation.inletValve,
            displayValue: '${simulation.inletValve.toStringAsFixed(0)}%',
            description: 'Регулирует расход пара на отопление',
            min: 0,
            max: 100,
            onChanged: simulation.setInletValve,
          ),
          _ParameterSlider(
            label: 'Клапан 10 · отвод из грелок',
            value: simulation.outletValve,
            displayValue: '${simulation.outletValve.toStringAsFixed(0)}%',
            description: 'Регулирует отвод конденсата из грелок',
            min: 0,
            max: 100,
            onChanged: simulation.setOutletValve,
          ),
          _ParameterSlider(
            label: 'Клапан 13 · возврат конденсата',
            value: simulation.drainValve,
            displayValue: '${simulation.drainValve.toStringAsFixed(0)}%',
            description: 'Регулирует работу конденсатоотводчика в тёплый ящик',
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
          const _SectionLabel('ТЕКУЩИЕ ПАРАМЕТРЫ'),
          const SizedBox(height: 10),
          _ReadoutRow(
            icon: Icons.speed,
            label: 'Давление на входе редуктора · котёл',
            value: '${simulation.boilerPressure.toStringAsFixed(2)} бар',
            color: simulation.boilerOverpressure
                ? AppColors.danger
                : AppColors.steam,
          ),
          const SizedBox(height: 9),
          _ReadoutRow(
            icon: Icons.tune,
            label: 'Давление на выходе редуктора',
            value: '${simulation.workingPressure.toStringAsFixed(2)} бар',
            color: simulation.downstreamOverpressure
                ? AppColors.danger
                : AppColors.steam,
          ),
          const SizedBox(height: 9),
          _ReadoutRow(
            icon: Icons.air,
            label: 'Расход пара в отопительную магистраль',
            value: '${simulation.steamFlowKgPerHour.toStringAsFixed(0)} кг/ч',
            color: AppColors.steam,
          ),
          const SizedBox(height: 9),
          _ReadoutRow(
            icon: Icons.water_drop_outlined,
            label: 'Степень сухости после сепаратора',
            value: '${simulation.steamQuality.toStringAsFixed(0)}%',
            color: AppColors.water,
          ),
          const SizedBox(height: 9),
          _ReadoutRow(
            icon: Icons.thermostat,
            label: 'Температура грелок',
            value: '${simulation.heaterTemperature.toStringAsFixed(1)} °C',
            color: AppColors.water,
          ),
          const SizedBox(height: 9),
          _ReadoutRow(
            icon: Icons.device_thermostat,
            label: 'Температура окружающей среды',
            value:
                '${SteamSimulation.ambientTemperatureC.toStringAsFixed(0)} °C',
            color: AppColors.muted,
          ),
          const SizedBox(height: 9),
          _ReadoutRow(
            icon: Icons.opacity,
            label: 'Конденсатная коробка',
            value: '${(simulation.condensateLevel * 100).toStringAsFixed(0)}%',
            color: simulation.condensateLevel >= 0.8
                ? AppColors.danger
                : AppColors.water,
          ),
          const SizedBox(height: 9),
          _ReadoutRow(
            icon: Icons.water,
            label: 'Конденсат в грелках',
            value:
                '${(simulation.heaterCondensateLevel * 100).toStringAsFixed(0)}%',
            color: simulation.heaterCondensateLevel >= 0.8
                ? AppColors.danger
                : AppColors.water,
          ),
          const SizedBox(height: 9),
          _ReadoutRow(
            icon: Icons.inventory_2_outlined,
            label: 'Тёплый ящик',
            value: '${(simulation.warmTankLevel * 100).toStringAsFixed(0)}%',
            color: simulation.warmTankLevel >= 0.9
                ? AppColors.danger
                : AppColors.water,
          ),
          if (simulation.condensateLevel >= 0.8 ||
              simulation.heaterCondensateLevel >= 0.8 ||
              simulation.warmTankLevel >= 0.9) ...[
            const SizedBox(height: 14),
            _WarningBanner(
              message: simulation.condensateOverflow
                  ? 'Переполнение: проверьте отвод конденсата'
                  : 'Критический уровень конденсата — проверьте клапаны 10 и 13',
            ),
          ],
          if (simulation.workingPressure < 1.0 &&
              !simulation.reducerFailed) ...[
            const SizedBox(height: 10),
            const _WarningBanner(
              message: 'Недостаточное давление пара в отопительной магистрали',
            ),
          ],
          if (simulation.reducerFailed) ...[
            const SizedBox(height: 10),
            const _WarningBanner(
              message: 'Авария: отказ редуктора — давление не регулируется',
            ),
          ],
          if (simulation.downstreamOverpressure) ...[
            const SizedBox(height: 10),
            const _WarningBanner(
              message: 'Авария: повышенное давление после редуктора',
            ),
          ],
          if (simulation.safetyValveOpen) ...[
            const SizedBox(height: 10),
            const _WarningBanner(
              message: 'Аварийный сброс пара: предохранительный клапан открыт',
            ),
          ],
          if (simulation.boilerOverpressure) ...[
            const SizedBox(height: 10),
            const _WarningBanner(
              message: 'Авария: достигнуто максимальное давление котла',
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainder = seconds % 60;
    final formattedMinutes = minutes.toString().padLeft(2, '0');
    final formattedSeconds = remainder.toString().padLeft(2, '0');
    if (hours == 0) return '$formattedMinutes:$formattedSeconds';
    return '${hours.toString().padLeft(2, '0')}:'
        '$formattedMinutes:$formattedSeconds';
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
    this.description,
    this.divisions,
  });

  final String label;
  final double value;
  final String displayValue;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final String? description;

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
        if (description != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              description!,
              style: const TextStyle(color: AppColors.muted, fontSize: 10),
            ),
          ),
      ],
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danger.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.danger, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
        ],
      ),
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
