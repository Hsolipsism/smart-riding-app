import { access, ble, constant } from '@kit.ConnectivityKit'
import { abilityAccessCtrl, bundleManager, common, Permissions } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

// BLE设备信息
export interface BLEDevice {
  deviceId: string
  deviceName: string
  rssi: number
}

// BLE扫描回调
export type BLEScanCallback = (devices: BLEDevice[]) => void

// 连接状态枚举
export enum ConnectionState {
  STATE_CONNECTING = 1,
  STATE_CONNECTED = 2,
  STATE_DISCONNECTING = 3,
  STATE_DISCONNECTED = 4
}

export class BLEManager {
  private static instance: BLEManager
  private context: common.UIAbilityContext | null = null
  private discoveredDevices: BLEDevice[] = []
  private isScanning: boolean = false
  private scanCallback: BLEScanCallback | null = null
  private gattClientDevice: ble.GattClientDevice | null = null
  private permissions: Array<Permissions> = ['ohos.permission.ACCESS_BLUETOOTH', 'ohos.permission.LOCATION']
  private scanTimeoutID: number = -1
  private readonly SCAN_TIMEOUT_MS: number = 10000 // 10秒扫描超时

  private constructor() {}

  static getInstance(): BLEManager {
    if (!BLEManager.instance) {
      BLEManager.instance = new BLEManager()
    }
    return BLEManager.instance
  }

  setContext(context: common.UIAbilityContext): void {
    this.context = context
  }

  // 请求蓝牙权限
  async requestPermissions(): Promise<boolean> {
    if (!this.context) {
      console.error('BLEManager: Context is null')
      return false
    }

    try {
      // 检查权限状态
      const grantStatus = await this.checkPermissions()
      if (grantStatus) {
        console.info('BLEManager: Permissions already granted')
        return true
      }

      // 请求权限
      const atManager = abilityAccessCtrl.createAtManager()
      const result = await atManager.requestPermissionsFromUser(this.context, this.permissions)
      const authResults = result.authResults

      // 检查授权结果
      if (authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        console.info('BLEManager: Permission granted')
        return true
      } else {
        console.error('BLEManager: Permission denied')
        return false
      }
    } catch (error) {
      console.error('BLEManager: Request permissions failed', error)
      return false
    }
  }

  // 检查权限是否已授予
  private async checkPermissions(): Promise<boolean> {
    try {
      const bundleInfo = await bundleManager.getBundleInfoForSelf(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
      )
      const tokenId = bundleInfo.appInfo.accessTokenId
      const atManager = abilityAccessCtrl.createAtManager()
      const result = await atManager.checkAccessToken(tokenId, 'ohos.permission.ACCESS_BLUETOOTH')
      return result === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
    } catch (error) {
      console.error('BLEManager: Check permissions failed', error)
      return false
    }
  }

  // 检查蓝牙状态
  isBluetoothEnabled(): boolean {
    let state: access.BluetoothState = access.BluetoothState.STATE_OFF
    try {
      state = access.getState()
    } catch (error) {
      console.error('BLEManager: getState failed', error)
    }
    return state === access.BluetoothState.STATE_ON || state === access.BluetoothState.STATE_TURNING_ON
  }

  // 启用蓝牙
  enableBluetooth(): void {
    try {
      access.enableBluetooth()
    } catch (error) {
      console.error('BLEManager: enableBluetooth failed', error)
    }
  }

  // 禁用蓝牙
  disableBluetooth(): void {
    try {
      access.disableBluetooth()
    } catch (error) {
      console.error('BLEManager: disableBluetooth failed', error)
    }
  }

  // 开始扫描
  startScan(callback: BLEScanCallback): boolean {
    if (this.isScanning) {
      console.info('BLEManager: Already scanning')
      return false
    }

    this.scanCallback = callback
    this.discoveredDevices = []
    this.isScanning = true

    // 检查蓝牙状态
    const btEnabled = this.isBluetoothEnabled()
    console.info('BLEManager: Bluetooth enabled:', btEnabled)

    // 如果蓝牙未开启，先开启
    if (!btEnabled) {
      console.info('BLEManager: Bluetooth not enabled, enabling...')
      this.enableBluetooth()
      // 等待蓝牙开启后再扫描
      setTimeout(() => {
        this.performScan()
      }, 1000)
    } else {
      this.performScan()
    }

    return true
  }

  private performScan(): void {
    console.info('BLEManager: Performing scan...')

    // 订阅设备发现事件
    try {
      ble.on('BLEDeviceFind', (results: Array<ble.ScanResult>) => {
        console.info('BLEManager: Found devices:', results.length)
        results.forEach((result: ble.ScanResult) => {
          const deviceId = result.deviceId
          const rssiValue = result.rssi
          const deviceName = result.deviceName || '未知设备'

          console.info('BLEManager: Device found -', deviceName, deviceId, rssiValue)

          // 检查是否已存在
          const existingIndex = this.discoveredDevices.findIndex((d: BLEDevice) => d.deviceId === deviceId)
          if (existingIndex >= 0) {
            this.discoveredDevices[existingIndex].rssi = rssiValue
          } else {
            this.discoveredDevices.push({
              deviceId: deviceId,
              deviceName: deviceName,
              rssi: rssiValue
            })
          }

          // 通知回调
          if (this.scanCallback) {
            this.scanCallback([...this.discoveredDevices])
          }
        })
      })

      // 扫描参数 - 使用低功率模式
      const scanOptions: ble.ScanOptions = {
        interval: 1000,
        dutyMode: ble.ScanDuty.SCAN_MODE_LOW_POWER,
        matchMode: ble.MatchMode.MATCH_MODE_AGGRESSIVE
      }

      // 创建过滤器 - 不指定deviceId让它接受所有设备
      const scanFilter: ble.ScanFilter = {
        // 不设置 deviceId，接受所有设备
      }

      // 开始扫描
      ble.startBLEScan([scanFilter], scanOptions)
      console.info('BLEManager: Started BLE scan')
      // 启动扫描超时保护
      this.startScanTimeoutCountdown()
    } catch (error) {
      const err = error as BusinessError
      console.error('BLEManager: Start scan failed', err.code, err.message)
      this.isScanning = false
    }
  }

  // 扫描超时保护
  private startScanTimeoutCountdown(): void {
    clearTimeout(this.scanTimeoutID)
    this.scanTimeoutID = setTimeout(() => {
      console.info('BLEManager: Scan timeout, stopping scan...')
      this.stopScan()
    }, this.SCAN_TIMEOUT_MS)
  }

  // 停止扫描
  stopScan(): void {
    // 清除扫描超时计时器
    clearTimeout(this.scanTimeoutID)
    this.scanTimeoutID = -1

    if (!this.isScanning) {
      return
    }

    try {
      ble.off('BLEDeviceFind')
      ble.stopBLEScan()
      this.isScanning = false
      console.info('BLEManager: Stopped scanning')
    } catch (error) {
      const err = error as BusinessError
      console.error('BLEManager: Stop scan failed', err.code, err.message)
    }
  }

  // 连接设备
  async connect(deviceId: string): Promise<boolean> {
    return new Promise((resolve) => {
      try {
        // 创建GATT客户端
        this.gattClientDevice = ble.createGattClientDevice(deviceId)

        // 订阅连接状态变化
        this.gattClientDevice.on('BLEConnectionStateChange', (data: ble.BLEConnectionChangeState) => {
          console.info('BLEManager: Connection state changed:', data.state)
          if (data.state === constant.ProfileConnectionState.STATE_CONNECTED) {
            console.info('BLEManager: Connected to device:', deviceId)
          } else if (data.state === constant.ProfileConnectionState.STATE_DISCONNECTED) {
            console.info('BLEManager: Disconnected from device:', deviceId)
          }
        })

        // 连接
        this.gattClientDevice.connect()
        console.info('BLEManager: Connecting to device:', deviceId)
        resolve(true)
      } catch (error) {
        const err = error as BusinessError
        console.error('BLEManager: Connect failed', err.code, err.message)
        resolve(false)
      }
    })
  }

  // 断开连接
  disconnect(): void {
    if (this.gattClientDevice) {
      try {
        this.gattClientDevice.off('BLEConnectionStateChange')
        this.gattClientDevice.disconnect()
        console.info('BLEManager: Disconnected')
      } catch (error) {
        const err = error as BusinessError
        console.error('BLEManager: Disconnect failed', err.code, err.message)
      }
    }
  }

  // 关闭设备并释放资源
  close(): void {
    if (this.gattClientDevice) {
      try {
        this.gattClientDevice.close()
        this.gattClientDevice = null
        console.info('BLEManager: Device closed')
      } catch (error) {
        const err = error as BusinessError
        console.error('BLEManager: Close failed', err.code, err.message)
      }
    }
  }

  isCurrentlyScanning(): boolean {
    return this.isScanning
  }
}
