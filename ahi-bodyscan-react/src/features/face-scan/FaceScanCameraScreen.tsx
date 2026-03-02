import React, { useState, useEffect, useRef } from 'react';
import styled from 'styled-components';
import { useNavigate, useLocation } from 'react-router-dom';
import { theme } from '../../styles/theme';
import { Layout } from '../../components/layout/Layout';
import { PrimaryGradientButton } from '../../components/common/Button';
import { Card } from '../../components/common/Card';
import useRPPG, { ProgressType } from '../../hooks/useRPPG';
import useSDKFaceMesh from '../../hooks/useSDKFaceMesh';
import useNotification from '../../hooks/useNotification';
import { saveScanResult } from '../../utils/scanDataHelpers';
import { ImageQuality } from './components/sdk/ImageQuality';
import { ParticleBackground } from './components/ParticleBackground';
import { RiveHUD, SimpleFaceGuide } from './components/RiveHUD';
import { PPGSignalChart } from './components/PPGSignalChart';
import { BHALambdaService } from '../../services/lambda/BHALambdaService';

const CameraContainer = styled.div`
  position: relative;
  width: 100%;
  height: 100vh;
  background: #000;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  
  @keyframes spin {
    to { transform: rotate(360deg); }
  }
`;

const VideoContainer = styled.div`
  position: relative;
  width: 100%;
  max-width: 940px;
  height: 100vh;
  background: #000;
  z-index: 10;
  display: flex;
  align-items: center;
  justify-content: center;
`;

const VideoElement = styled.video`
  width: 100%;
  height: 100%;
  object-fit: cover;
  /* Removed transform: scaleX(-1) to fix face mesh alignment */
`;

const CanvasElement = styled.canvas`
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  pointer-events: none;
  z-index: 10;
`;

const LoadingOverlay = styled.div`
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.8);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  z-index: 50;
  color: ${theme.colors.textWhite};
  
  .spinner {
    width: 48px;
    height: 48px;
    border: 3px solid ${theme.colors.divider};
    border-top-color: ${theme.colors.primaryBlue};
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin-bottom: ${theme.dimensions.paddingLarge};
  }
  
  @keyframes spin {
    to { transform: rotate(360deg); }
  }
`;

const ErrorMessage = styled.div`
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  background: ${theme.colors.error};
  color: ${theme.colors.textWhite};
  padding: ${theme.dimensions.paddingLarge};
  border-radius: ${theme.dimensions.radiusMedium};
  text-align: center;
  max-width: 400px;
  z-index: 50;
`;

const CloseButton = styled.button`
  position: absolute;
  top: ${theme.dimensions.paddingLarge};
  left: ${theme.dimensions.paddingLarge};
  width: 32px;
  height: 32px;
  background: rgba(255, 255, 255, 0.9);
  border: none;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  z-index: 50;
  
  svg {
    width: 16px;
    height: 16px;
    color: ${theme.colors.textPrimary};
  }
`;


const InfoCard = styled(Card)`
  position: absolute;
  bottom: 120px;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(255, 255, 255, 0.95);
  padding: ${theme.dimensions.paddingMedium};
  min-width: 300px;
  z-index: 10;
`;

const MetricRow = styled.div`
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: ${theme.dimensions.paddingSmall};
  
  &:last-child {
    margin-bottom: 0;
  }
`;

const MetricLabel = styled.span`
  font-size: ${theme.typography.bodySmall.fontSize};
  color: ${theme.colors.textSecondary};
`;

const MetricValue = styled.span`
  font-size: ${theme.typography.bodyMedium.fontSize};
  font-weight: 600;
  color: ${theme.colors.textPrimary};
`;

const ProgressContainer = styled.div`
  position: absolute;
  top: ${theme.dimensions.paddingLarge};
  left: 50%;
  transform: translateX(-50%);
  background: rgba(255, 255, 255, 0.95);
  padding: ${theme.dimensions.paddingMedium} ${theme.dimensions.paddingLarge};
  border-radius: ${theme.dimensions.radiusMedium};
  display: flex;
  align-items: center;
  gap: ${theme.dimensions.paddingMedium};
  z-index: 10;
`;

const ProgressText = styled.span`
  font-size: ${theme.typography.bodyMedium.fontSize};
  color: ${theme.colors.textPrimary};
  font-weight: 500;
`;

const NotificationContainer = styled.div<{ type: 'info' | 'warning' | 'error' }>`
  position: absolute;
  top: 80px;
  left: 50%;
  transform: translateX(-50%);
  background: ${props => props.type === 'error' ? theme.colors.error : theme.colors.warning};
  color: ${theme.colors.textWhite};
  padding: ${theme.dimensions.paddingMedium} ${theme.dimensions.paddingLarge};
  border-radius: ${theme.dimensions.radiusMedium};
  z-index: 10;
`;

// Helper constants for notifications
const NOTIFICATION_NO_FACE_DETECTED = {
  id: 'no-face',
  text: 'No face detected. Please position your face in the camera view.',
  type: 'warning' as const,
  timeout: 5000,
};

const NOTIFICATION_FACE_ORIENT_WARNING = {
  id: 'face-orient',
  text: 'Please face the camera directly',
  type: 'warning' as const,
  timeout: 3000,
};

const NOTIFICATION_FACE_SIZE_WARNING = {
  id: 'face-size',
  text: 'Please adjust your distance from the camera',
  type: 'warning' as const,
  timeout: 3000,
};

const NOTIFICATION_INTERFERENCE_WARNING = {
  id: 'interference',
  text: 'Poor lighting conditions detected',
  type: 'warning' as const,
  timeout: 3000,
};

export const FaceScanCameraScreen: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const videoRef = useRef<HTMLVideoElement>(null!);
  const canvasRef = useRef<HTMLCanvasElement>(null!);
  
  // Get user data from location state or localStorage
  const [userData, setUserData] = useState<any>(null);
  
  // Mobile detection
  const [isMobile, setIsMobile] = useState(false);
  
  useEffect(() => {
    const checkMobile = () => {
      setIsMobile(window.innerWidth < 768);
    };
    
    checkMobile();
    window.addEventListener('resize', checkMobile);
    
    return () => window.removeEventListener('resize', checkMobile);
  }, []);
  
  // UI State for Rive HUD
  const [haloState, setHaloState] = useState(0);
  const [guideText, setGuideText] = useState('Place your face in the outline...');
  const [contextText, setContextText] = useState('Make sure your face is well lit');
  const [showChart, setShowChart] = useState(false);
  const [completionStates, setCompletionStates] = useState({
    bpm_isComplete: false,
    rr_isComplete: false,
    spo2_isComplete: false,
    hrv_isComplete: false,
    si_isComplete: false,
    bp_isComplete: false,
  });
  const [useRiveHUD, setUseRiveHUD] = useState(true); // Toggle for Rive vs fallback
  const [blinkCount, setBlinkCount] = useState(0);
  const [isProcessingResults, setIsProcessingResults] = useState(false);
  const [hasSubmittedToLambda, setHasSubmittedToLambda] = useState(false);
  
  // Face state tracking with error window
  const errorWindow = 10;
  const [faceDetectionLog, setFaceDetectionLog] = useState(Array(errorWindow).fill(true));
  const [faceSizeLog, setFaceSizeLog] = useState(Array(errorWindow).fill(true));
  const [faceOrientLog, setFaceOrientLog] = useState(Array(errorWindow).fill(true));
  
  useEffect(() => {
    // Get profile data
    const selectedProfile = localStorage.getItem('selectedProfile');
    if (!selectedProfile) {
      alert('Please select a profile first from the Home screen');
      navigate('/home');
      return;
    }
    
    try {
      const profile = JSON.parse(selectedProfile);
      const profileData = {
        sex: profile.gender.toLowerCase(),
        age: profile.age,
        height: Math.round(profile.height),
        weight: Math.round(profile.weight),
        heightUnit: profile.heightUnit || 'cm',
        weightUnit: profile.weightUnit || 'kg',
        exerciseLevel: profile.exerciseLevel || 'inactive',
        chronicMedication: profile.chronicMedication || 'none',
        smokingStatus: profile.smokingStatus || 'never',
        diabetesStatus: profile.diabetesStatus || 'no',
        hasHypertension: profile.hasHypertension || 'no',
        takingBPMedication: profile.takingBPMedication || 'no',
        dateOfBirth: profile.dateOfBirth
      };
      setUserData(profileData);
    } catch (error) {
      console.error('Error parsing selected profile:', error);
      alert('Error loading profile. Please select a profile again.');
      navigate('/home');
    }
  }, [navigate]);
  
  // Notification management
  const {
    message,
    addNotification,
    clearAllNotifications,
  } = useNotification();
  
  // Face detection callbacks
  const onFaceDetectionChange = (faceDetected: boolean) => {
    if (processing && !faceDetected) {
      addNotification(NOTIFICATION_NO_FACE_DETECTED);
    }
  };
  
  const onUnsupportedDeviceCb = () => {
    stopHandler();
    navigate('/capture/error', { state: { error: 'Device not supported. Please ensure you have a camera with at least 15 FPS capability.' } });
  };
  
  const onCalculationEndedCb = () => {
    // Don't navigate away - just stop the camera and process results
    clearAllNotifications();
    stop();
    handleScanComplete();
  };
  
  const onInterferenceWarningCb = () => {
    addNotification(NOTIFICATION_INTERFERENCE_WARNING);
  };
  
  const onFaceOrientWarningCb = () =>
    processing && addNotification(NOTIFICATION_FACE_ORIENT_WARNING);
  
  const onFaceSizeWarningCb = () =>
    processing && addNotification(NOTIFICATION_FACE_SIZE_WARNING);
  
  // Face detection state
  const [faceDetected, setFaceDetected] = useState(false);
  
  // Initialize RPPG SDK
  const {
    rppgData,
    ready,
    error,
    rppgInstance,
    isAllDataCalculated,
    imageQualityFlags,
    progressType,
    processing,
    checkFps,
    start,
    stop,
    closeCamera,
  } = useRPPG({
    videoElement: videoRef,
    canvasElement: canvasRef,
    userData: userData || { sex: 'male', age: 30, weight: 70, height: 170 },
    onUnsupportedDeviceCb,
    onAllDataCalculatedCb: onCalculationEndedCb,
    onCalculationEndedCb,
    onInterferenceWarningCb,
    onFaceOrientWarningCb,
    onFaceSizeWarningCb,
  });
  
  // Initialize SDK face mesh visualization
  useSDKFaceMesh({
    canvasElement: canvasRef,
    videoElement: videoRef,
    frameData: rppgData.frameData,
    enabled: processing,
  });
  
  // Helper function to update face state logs
  const updateFaceStateLog = (log: boolean[], newValue: boolean): boolean => {
    const newLog = [...log];
    newLog.push(newValue);
    if (newLog.length > errorWindow) {
      newLog.shift();
    }
    return !newLog.every(val => val === false);
  };

  // Update face detection based on SDK data
  useEffect(() => {
    if (rppgData.frameData?.rppgTrackerData.landmarks && rppgData.frameData.rppgTrackerData.landmarks.length > 0) {
      setFaceDetected(true);
      onFaceDetectionChange(true);
    } else if (processing) {
      setFaceDetected(false);
      onFaceDetectionChange(false);
    }
    
    // Update blink count
    if (rppgData.frameData?.rppgTrackerData.eyeBlinkStatus) {
      setBlinkCount(prev => prev + 1);
    }
  }, [rppgData.frameData, processing]);
  
  // Update UI states based on scanning progress and face detection
  useEffect(() => {
    if (!processing) {
      setHaloState(0);
      setGuideText('Place your face in the outline...');
      setContextText('Make sure your face is well lit');
      setShowChart(false);
      return;
    }
    
    const progress = rppgData.measurementProgress?.progressPercent || 0;
    const { measurementData, measurementSignal, hrvMetrics, bloodPressure } = rppgData;
    const { imageQualityFlags } = rppgData.frameData?.rppgTrackerData || {};
    
    // Check face detection with error window
    const isFaceDetected = updateFaceStateLog(
      faceDetectionLog,
      !!(rppgData.frameData?.rppgTrackerData.landmarks &&
      rppgData.frameData.rppgTrackerData.landmarks.length > 0)
    );
    
    const isFaceNear = imageQualityFlags ? updateFaceStateLog(
      faceSizeLog,
      imageQualityFlags.faceSizeFlag
    ) : true;
    
    const isFaceOriented = imageQualityFlags ? updateFaceStateLog(
      faceOrientLog,
      imageQualityFlags.faceOrientFlag  
    ) : true;
    
    // Error states
    if (!isFaceDetected && processing) {
      setHaloState(3);
      setGuideText('No Face Detected');
      setContextText('Please position your face in the oval');
      setShowChart(false);
      return;
    }
    
    if (!isFaceNear) {
      setHaloState(3);
      setGuideText('Too Far Away');
      setContextText('Please move closer to camera');
      setShowChart(false);
      return;
    }
    
    if (!isFaceOriented) {
      setHaloState(3);
      setGuideText('Face not straight');
      setContextText('Please face camera directly');
      setShowChart(false);
      return;
    }
    
    // Blink check
    if (progress > 50 && progress < 90 && blinkCount < 1) {
      setHaloState(3);
      setGuideText('Checking...');
      setContextText('Please blink');
      setShowChart(false);
      return;
    }
    
    // Progress states
    if (progress > 0 && progress < 100) {
      setHaloState(1);
      setGuideText('Calibrating System...');
      setContextText('Please keep still');
    }
    
    if (measurementSignal?.signal && measurementSignal.signal.length > 50) {
      setGuideText('Interpreting Vital Signs...');
      setContextText("This won't take long");
      setShowChart(true);
    }
    
    if (progress > 100) {
      setHaloState(2);
      setGuideText('Analyzing Biometrics...');
      setContextText('Thank you for your patience...');
    }
    
    // Update completion badges
    setCompletionStates({
      bpm_isComplete: (measurementData?.bpm || 0) > 0,
      rr_isComplete: (measurementData?.rr || 0) > 0,
      spo2_isComplete: (measurementData?.oxygen || 0) > 0,
      hrv_isComplete: (hrvMetrics?.sdnn || 0) > 0 && (hrvMetrics?.rmssd || 0) > 0,
      si_isComplete: (rppgData.stressIndex || 0) > 0,
      bp_isComplete: (bloodPressure?.systolic || 0) > 0 && (bloodPressure?.diastolic || 0) > 0,
    });
    
    // Check if all data is ready
    if (bloodPressure?.systolic && bloodPressure.systolic > 0 && 
        bloodPressure?.diastolic && bloodPressure.diastolic > 0 &&
        measurementData?.bpm && measurementData.bpm > 0 &&
        measurementData?.oxygen && measurementData.oxygen > 0 &&
        measurementData?.rr && measurementData.rr > 0 &&
        hrvMetrics?.ibi && hrvMetrics.ibi > 0 &&
        hrvMetrics?.rmssd && hrvMetrics.rmssd > 0 &&
        hrvMetrics?.sdnn && hrvMetrics.sdnn > 0) {
      setHaloState(4);
      setShowChart(false);
      setGuideText('Finalizing Results...');
      setContextText('Thank you for your patience');
    }
  }, [processing, rppgData, faceDetectionLog, faceSizeLog, faceOrientLog, blinkCount]);
  
  // Auto-start scan when ready
  useEffect(() => {
    if (ready && userData && !processing) {
      // Small delay to ensure UI is ready
      setTimeout(() => {
        startHandler();
      }, 1000);
    }
  }, [ready, userData]);
  
  
  // Handle scan errors
  useEffect(() => {
    if (error) {
      navigate('/capture/error', { state: { error: error.message } });
    }
  }, [error, navigate]);
  
  const startHandler = () => {
    clearAllNotifications();
    start();
  };
  
  const stopHandler = () => {
    clearAllNotifications();
    stop();
    closeCamera();
    navigate('/scan/face/preparation');
  };
  
  const handleScanComplete = async () => {
    // Prevent duplicate submissions
    if (hasSubmittedToLambda || isProcessingResults) {
      return;
    }
    
    // Show loading state while processing
    setIsProcessingResults(true);
    setHasSubmittedToLambda(true);
    
    const { measurementData, hrvMetrics, bloodPressure } = rppgData;
    
    if (!measurementData) {
      alert('No scan data received. Please try again.');
      closeCamera();
      navigate('/scan/face/preparation');
      return;
    }
    
    // Map SDK data to results format
    const results: any = {
      heartRate: measurementData.bpm || 0,
      heartRateVariability: hrvMetrics?.sdnn || 0,
      respiratoryRate: measurementData.rr || 0,
      oxygenSaturation: measurementData.oxygen || 0,
      systolicBP: bloodPressure?.systolic || 0,
      diastolicBP: bloodPressure?.diastolic || 0,
      stressLevel: mapStressStatus(measurementData.stressStatus),
      stressScore: 0.5, // Default medium stress
      ibi: hrvMetrics?.ibi,
      rmssd: hrvMetrics?.rmssd,
      sdnn: hrvMetrics?.sdnn,
    };
    
    // Submit to Lambda for health assessment
    console.log('🚀 Starting Lambda submission...');
    console.log('User data for Lambda:', userData);
    try {
      const lambdaData = BHALambdaService.prepareScanData(results, userData);
      const bhaResponse = await BHALambdaService.submitForHealthAssessment(lambdaData);
      const enhancedResults = BHALambdaService.processBHAResponse(results, bhaResponse);
      
      // Use enhanced results if Lambda succeeded
      console.log('✅ Lambda succeeded, merging results...');
      Object.assign(results, enhancedResults);
      console.log('📊 Final results with Lambda data:', results);
    } catch (error) {
      console.error('❌ Lambda health assessment failed:', error);
      // Add error message to results so user knows Lambda failed
      results.lambdaError = error instanceof Error ? error.message : 'Lambda assessment failed';
      // Continue with basic results if Lambda fails
    }
    
    // Save scan result
    const selectedProfile = localStorage.getItem('selectedProfile');
    if (selectedProfile) {
      const profile = JSON.parse(selectedProfile);
      const scanId = `face_${Date.now()}`;
      
      const scanData = {
        id: scanId,
        profileId: profile.id,
        scanType: 'face' as const,
        status: 'completed' as const,
        progress: 100,
        startedAt: new Date(Date.now() - 60000).toISOString(),
        completedAt: new Date().toISOString(),
        data: results,
      };
      
      saveScanResult(profile.id, scanData);
    }
    
    // Close camera before navigating
    closeCamera();
    
    // Navigate to results
    navigate('/face-scan-results', {
      state: {
        scanResults: results,
        userData: userData || {},
      },
    });
  };
  
  const mapStressStatus = (status: any): string => {
    switch (status) {
      case 'LOW': return 'low';
      case 'NORMAL': return 'normal';
      case 'ELEVATED': return 'elevated';
      case 'VERY_HIGH': return 'high';
      default: return 'normal';
    }
  };
  
  const handleClose = () => {
    stopHandler();
    closeCamera();
    navigate('/scan/face/preparation');
  };
  
  const getProgressMessage = () => {
    switch (progressType) {
      case ProgressType.CALIBRATING:
        return 'Calibrating camera...';
      case ProgressType.CALCULATING:
        return 'Analyzing vital signs...';
      default:
        return 'Preparing...';
    }
  };
  
  if (!userData) {
    return (
      <Layout showNavigation={false}>
        <CameraContainer>
          <LoadingOverlay>
            <div className="spinner" />
            <p>Loading user profile...</p>
          </LoadingOverlay>
        </CameraContainer>
      </Layout>
    );
  }

  return (
    <Layout showNavigation={false}>
      <CameraContainer>
        {/* Layer 0: Animated particle background */}
        <ParticleBackground 
          particleColor="106, 0, 255"
          backgroundColor="#000000"
        />
        
        {/* Layer 1: Video feed */}
        <VideoContainer>
          <VideoElement ref={videoRef} autoPlay playsInline muted />
          <CanvasElement 
            ref={canvasRef}
          />
        </VideoContainer>
        
        {/* Layer 2: Rive HUD with face guide oval - only show when ready */}
        {ready && processing && (
          <RiveHUD
            haloState={haloState}
            guideText={guideText}
            contextText={contextText}
            bpmValue={rppgData.measurementData?.bpm || '-'}
            completionStates={completionStates}
            onBackTapped={handleClose}
          />
        )}
        
        {/* Layer 3: PPG Signal Chart */}
        <PPGSignalChart
          signal={rppgData.measurementSignal?.signal || []}
          visible={showChart}
          color="white"
          lineWidth={1}
          maxSamples={75}
        />
        
        {/* Close button removed - using back button in Rive HUD instead */}
        
        {/* Progress indicator - removed as it's now in Rive HUD */}
        
        {/* UI elements now handled by Rive HUD - keeping commented for reference */}
        {/* Image Quality is shown through halo states in Rive */}
        {/* Notifications are shown through guide text in Rive */}
        {/* Live metrics are shown through completion badges in Rive */}
        
        {/* Stop button removed - using back button in Rive HUD instead */}
        
        {/* Loading state */}
        {!ready && !error && (
          <LoadingOverlay>
            <div className="spinner" />
            <p>Initializing face scan...</p>
          </LoadingOverlay>
        )}
        
        {/* Error state - removed as it's handled by useEffect */}
        
        {/* Processing results overlay */}
        {isProcessingResults && (
          <LoadingOverlay style={{ zIndex: 200 }}>
            <div className="spinner" />
            <p>Processing your health assessment...</p>
            <p style={{ fontSize: '14px', marginTop: '10px', opacity: 0.8 }}>
              Analyzing vital signs and generating insights
            </p>
          </LoadingOverlay>
        )}
      </CameraContainer>
    </Layout>
  );
};