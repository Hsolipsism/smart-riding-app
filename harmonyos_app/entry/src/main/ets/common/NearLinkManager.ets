import { scan, ssap, constant } from '@kit.NearLinkKit'
import { BusinessError } from '@kit.BasicServicesKit'

// 星闪设备信息
export interface NearLinkDevice {
  deviceName: string
  address: string
}

// 星闪扫描回调
export type NearLinkScanCallback = (devices: NearLinkDevice[]) => void

// 星闪连接状态回调
export type NearLinkConnectionCallback = (success: boolean, message: string) => void

export class NearLinkManager {
  private static instance: NearLinkManager
  private discoveredDevices: NearLinkDevice[] = []
  private isScanning: boolean = false
  private scanCallback: NearLinkScanCallback | null = null
  private connectionCallback: NearLinkConnectionCallback | null = null
  private ssapClient: ssap.Client | null = null
  private targetDeviceName: string = ''
  private scanTimeoutID: number = -1
  private readonly SCAN_TIMEOUT_MS: number = 10000 // 10秒扫描超时

  private constructor() {}

  static getInstance(): NearLinkManager {
    if (!NearLinkManager.instance) {
      NearLinkManager.instance = new NearLinkManager()
    }
    return NearLinkManager.instance
  }

  // 开始扫描
  startScan(deviceName: string, callback: NearLinkScanCallback): boolean {
    if (this.isScanning) {
      console.info('NearLinkManager: Already scanning')
      return false
    }

    this.targetDeviceName = deviceName
    this.scanCallback = callback
    this.discoveredDevices = []
    this.isScanning = true

    console.info('NearLinkManager: Starting scan for device:', deviceName)

    // 注册设备发现回调
    this.registerDeviceFoundCallback()

    // 开始扫描
    this.performScan()

    return true
  }

  // 停止扫描
  stopScan(): void {
    console.info('NearLinkManager: Stopping scan')

    // 清除超时
    clearTimeout(this.scanTimeoutID)
    this.scanTimeoutID = -1

    if (!this.isScanning) {
      return
    }

    try {
      scan.off('deviceFound')
      scan.stopScan()
      this.isScanning = false
      console.info('NearLinkManager: Scan stopped')
    } catch (error) {
      const err = error as BusinessError
      console.error('NearLinkManager: Stop scan failed', err.code, err.message)
      this.isScanning = false
    }
  }

  // 注册设备发现回调
  private registerDeviceFoundCallback(): void {
    try {
      scan.on('deviceFound', (data: Array<scan.ScanResults>) => {
        console.info('NearLinkManager: Found devices:', data.length)

        for (let i = 0; i < data.length; i++) {
          const result = data[i]
          const deviceName = result.deviceName || '未知设备'
          const address = result.address

          console.info('NearLinkManager: Device found -', deviceName, address)

          // 检查是否已存在
          const existingIndex = this.discoveredDevices.findIndex((d: NearLinkDevice) => d.address === address)
          if (existingIndex < 0) {
            this.discoveredDevices.push({
              deviceName: deviceName,
              address: address
            })
          }

          // 通知回调
          if (this.scanCallback) {
            this.scanCallback([...this.discoveredDevices])
          }

          // 如果匹配目标设备名称，自动连接
          if (deviceName === this.targetDeviceName) {
            console.info('NearLinkManager: Found target device, connecting...')
            this.stopScan()
            this.connectToDevice(address)
          }
        }
      })
    } catch (error) {
      const err = error as BusinessError
      console.error('NearLinkManager: Register device found callback failed', err.code, err.message)
    }
  }

  // 执行扫描
  private performScan(): void {
    try {
      // 创建扫描过滤器（按设备名称）
      const scanFilter: scan.ScanFilters = {
        deviceName: this.targetDeviceName
      }

      // 扫描选项
      const scanOptions: scan.ScanOptions = {
        scanMode: 2 // 主动扫描模式
      }

      // 开始扫描
      scan.startScan([scanFilter], scanOptions)
        .then(() => {
          console.info('NearLinkManager: Start scan success')
          // 启动扫描超时保护
          this.startScanTimeoutCountdown()
        })
        .catch((err: BusinessError) => {
          console.error('NearLinkManager: Start scan failed', err.code, err.message)
          this.isScanning = false
        })
    } catch (error) {
      const err = error as BusinessError
      console.error('NearLinkManager: Perform scan failed', err.code, err.message)
      this.isScanning = false
    }
  }

  // 扫描超时保护
  private startScanTimeoutCountdown(): void {
    clearTimeout(this.scanTimeoutID)
    this.scanTimeoutID = setTimeout(() => {
      console.info('NearLinkManager: Scan timeout, stopping...')
      this.stopScan()
    }, this.SCAN_TIMEOUT_MS)
  }

  // 连接到设备
  private connectToDevice(address: string): void {
    console.info('NearLinkManager: Connecting to device:', address)

    try {
      // 创建SSAP客户端
      this.ssapClient = ssap.createClient(address)

      // 注册连接状态变化回调
      this.ssapClient.on('connectionStateChange', (data: ssap.ConnectionChangeState) => {
        console.info('NearLinkManager: Connection state changed:', data.state)
        if (data.state === constant.ConnectionState.STATE_CONNECTED) {
          console.info('NearLinkManager: Connected to device:', address)
        } else if (data.state === constant.ConnectionState.STATE_DISCONNECTED) {
          console.info('NearLinkManager: Disconnected from device:', address)
        }
      })

      // 连接
      this.ssapClient.connect()
        .then(() => {
          console.info('NearLinkManager: Connect request sent')
          if (this.connectionCallback) {
            this.connectionCallback(true, '星闪连接成功')
          }
        })
        .catch((err: BusinessError) => {
          console.error('NearLinkManager: Connect failed', err.code, err.message)
          if (this.connectionCallback) {
            this.connectionCallback(false, `连接失败: ${err.message}`)
          }
        })
    } catch (error) {
      const err = error as BusinessError
      console.error('NearLinkManager: Create client failed', err.code, err.message)
      if (this.connectionCallback) {
        this.connectionCallback(false, `创建连接失败: ${err.message}`)
      }
    }
  }

  // 设置连接状态回调
  setConnectionCallback(callback: NearLinkConnectionCallback): void {
    this.connectionCallback = callback
  }

  // 断开连接
  disconnect(): void {
    if (this.ssapClient) {
      try {
        this.ssapClient.off('connectionStateChange')
        this.ssapClient.disconnect()
          .then(() => {
            console.info('NearLinkManager: Disconnected')
          })
          .catch((err: BusinessError) => {
            console.error('NearLinkManager: Disconnect failed', err.code, err.message)
          })
        this.ssapClient.close()
        this.ssapClient = null
      } catch (error) {
        const err = error as BusinessError
        console.error('NearLinkManager: Disconnect error', err.code, err.message)
      }
    }
  }

  isCurrentlyScanning(): boolean {
    return this.isScanning
  }
}
