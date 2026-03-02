import React, { useEffect, useState } from 'react';
import styled from 'styled-components';
import { useRive, useStateMachineInput } from '@rive-app/react-canvas';
import { Fit, Alignment, Layout } from '@rive-app/canvas';

const HUDContainer = styled.div`
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: 50;
  pointer-events: none;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
`;

const RiveWrapper = styled.div`
  width: 100%;
  height: 100%;
  max-width: 100%;
  max-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  background: transparent;
  
  canvas {
    width: 100% !important;
    height: 100% !important;
    max-width: 100%;
    background: transparent !important;
    object-fit: contain;
    image-rendering: crisp-edges;
  }
`;

interface CompletionStates {
  bpm_isComplete: boolean;
  rr_isComplete: boolean;
  spo2_isComplete: boolean;
  hrv_isComplete: boolean;
  si_isComplete: boolean;
  bp_isComplete: boolean;
}

interface RiveHUDProps {
  haloState: number; // 0-4 for different states
  guideText: string;
  contextText: string;
  bpmValue: string | number;
  completionStates: CompletionStates;
  onBackTapped?: () => void;
}

export const RiveHUD: React.FC<RiveHUDProps> = ({
  haloState,
  guideText,
  contextText,
  bpmValue,
  completionStates,
  onBackTapped,
}) => {
  const [riveLoaded, setRiveLoaded] = useState(false);

  const { RiveComponent, rive } = useRive({
    src: '/assets/rive/hud.riv',
    stateMachines: 'SM',
    autoplay: true,
    layout: new Layout({
      fit: Fit.Contain,
      alignment: Alignment.Center,
    }),
    onLoad: () => {
      setRiveLoaded(true);
    },
    onLoadError: (event) => {
      console.error('Rive failed to load:', event);
      setRiveLoaded(false);
    },
  });

  // Get state machine inputs
  const haloStateInput = useStateMachineInput(rive, 'SM', 'haloState');
  const isCalibratedInput = useStateMachineInput(rive, 'SM', 'isCalibrated');
  const bpmCompleteInput = useStateMachineInput(rive, 'SM', 'bpm_isComplete');
  const rrCompleteInput = useStateMachineInput(rive, 'SM', 'rr_isComplete');
  const spo2CompleteInput = useStateMachineInput(rive, 'SM', 'spo2_isComplete');
  const hrvCompleteInput = useStateMachineInput(rive, 'SM', 'hrv_isComplete');
  const siCompleteInput = useStateMachineInput(rive, 'SM', 'si_isComplete');
  const bpCompleteInput = useStateMachineInput(rive, 'SM', 'bp_isComplete');

  // Update halo state
  useEffect(() => {
    if (haloStateInput && riveLoaded) {
      haloStateInput.value = haloState;
    }
  }, [haloState, haloStateInput, riveLoaded]);

  // Update calibration state
  useEffect(() => {
    if (isCalibratedInput && riveLoaded) {
      isCalibratedInput.value = haloState === 1 || haloState === 2;
    }
  }, [haloState, isCalibratedInput, riveLoaded]);

  // Update text elements
  useEffect(() => {
    if (rive && riveLoaded) {
      try {
        rive.setTextRunValue('guideText', String(guideText));
        rive.setTextRunValue('guideTextContext', String(contextText));
        rive.setTextRunValue('bpmValue', String(bpmValue));
      } catch (e) {
        console.warn('Error updating Rive text:', e);
      }
    }
  }, [guideText, contextText, bpmValue, rive, riveLoaded]);

  // Update completion states
  useEffect(() => {
    if (riveLoaded) {
      if (bpmCompleteInput) bpmCompleteInput.value = completionStates.bpm_isComplete;
      if (rrCompleteInput) rrCompleteInput.value = completionStates.rr_isComplete;
      if (spo2CompleteInput) spo2CompleteInput.value = completionStates.spo2_isComplete;
      if (hrvCompleteInput) hrvCompleteInput.value = completionStates.hrv_isComplete;
      if (siCompleteInput) siCompleteInput.value = completionStates.si_isComplete;
      if (bpCompleteInput) bpCompleteInput.value = completionStates.bp_isComplete;
    }
  }, [
    completionStates,
    bpmCompleteInput,
    rrCompleteInput,
    spo2CompleteInput,
    hrvCompleteInput,
    siCompleteInput,
    bpCompleteInput,
    riveLoaded,
  ]);

  // Handle back button tap
  useEffect(() => {
    if (rive && riveLoaded && onBackTapped) {
      const handleBackTap = () => {
        onBackTapped();
      };

      // Note: 'backTapped' is a custom event from the Rive file
      // @ts-ignore - Custom Rive event not in TypeScript definitions
      rive.on('backTapped' as any, handleBackTap);

      return () => {
        // @ts-ignore - Custom Rive event not in TypeScript definitions
        rive.off('backTapped' as any, handleBackTap);
      };
    }
  }, [rive, riveLoaded, onBackTapped]);

  return (
    <HUDContainer>
      <RiveWrapper>
        <RiveComponent />
      </RiveWrapper>
    </HUDContainer>
  );
};

// Alternative implementation if Rive file is not available - creates a simple face guide overlay
export const SimpleFaceGuide: React.FC<{
  haloState: number;
  guideText: string;
  contextText: string;
}> = ({ haloState, guideText, contextText }) => {
  const getHaloColor = () => {
    switch (haloState) {
      case 1: return '#4ade80'; // Green
      case 2: return '#3b82f6'; // Blue
      case 3: return '#ef4444'; // Red
      case 4: return '#f59e0b'; // Gold
      default: return '#6b7280'; // Gray
    }
  };

  return (
    <FallbackContainer>
      <FaceOval $haloColor={getHaloColor()} $haloState={haloState} />
      <GuideTextContainer>
        <GuideText>{guideText}</GuideText>
        <ContextText>{contextText}</ContextText>
      </GuideTextContainer>
    </FallbackContainer>
  );
};

const FallbackContainer = styled.div`
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: 50;
  pointer-events: none;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
`;

const FaceOval = styled.div<{ $haloColor: string; $haloState: number }>`
  width: 280px;
  height: 360px;
  border: 3px solid rgba(255, 255, 255, 0.3);
  border-radius: 50%;
  position: relative;
  
  &::before {
    content: '';
    position: absolute;
    top: -10px;
    left: -10px;
    right: -10px;
    bottom: -10px;
    border: 4px solid ${props => props.$haloColor};
    border-radius: 50%;
    opacity: ${props => props.$haloState > 0 ? 1 : 0};
    animation: ${props => props.$haloState > 0 && props.$haloState < 4 ? 'pulse 2s infinite' : 'none'};
  }
  
  @keyframes pulse {
    0%, 100% {
      transform: scale(1);
      opacity: 1;
    }
    50% {
      transform: scale(1.05);
      opacity: 0.7;
    }
  }
`;

const GuideTextContainer = styled.div`
  position: absolute;
  top: 80px;
  left: 50%;
  transform: translateX(-50%);
  text-align: center;
  background: rgba(0, 0, 0, 0.7);
  padding: 16px 32px;
  border-radius: 12px;
`;

const GuideText = styled.h3`
  color: white;
  font-size: 20px;
  font-weight: 600;
  margin: 0 0 8px 0;
`;

const ContextText = styled.p`
  color: rgba(255, 255, 255, 0.8);
  font-size: 14px;
  margin: 0;
`;