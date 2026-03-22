/**
 * 自动重连管理器
 * 负责星闪连接断开后自动重连
 */

import { NearLinkManager } from './NearLinkManager'
import { ConnectionType } from '../constants/BLEConstants'
import { PreferencesHelper } from '../utils/PreferencesHelper'

const AUTO_RECONNECT_ENABLED_KEY = 'autoReconnectEnabled'
const AUTO_RECONNECT_INTERVAL_KEY = 'autoReconnectInterval'
const DEFAULT_INTERVAL = 5 // 默认5秒

export class AutoReconnectManager {
  private static instance: AutoReconnectManager
  private reconnectTimerID: number = -1
  private isEnabled: boolean = false
  private intervalSeconds: number = DEFAULT_INTERVAL
  private nearLinkManager: NearLinkManager = NearLinkManager.getInstance()
  private preferencesHelper: PreferencesHelper = PreferencesHelper.getInstance()

  private constructor() {}

  static getInstance(): AutoReconnectManager {
    if (!AutoReconnectManager.instance) {
      AutoReconnectManager.instance = new AutoReconnectManager()
    }
    return AutoReconnectManager.instance
  }

  /**
   * 初始化
   */
  async init(): Promise<void> {
    // 从持久化存储加载设置
    this.isEnabled = await this.preferencesHelper.getBoolean(AUTO_RECONNECT_ENABLED_KEY, false)
    this.intervalSeconds = await this.preferencesHelper.getNumber(AUTO_RECONNECT_INTERVAL_KEY, DEFAULT_INTERVAL)

    // 监听连接状态变化
    this.nearLinkManager.setConnectionCallback((success: boolean, message: string) => {
      if (success) {
        // 连接成功，停止重连
        this.stopReconnect()
      }
    })

    // 如果启用且当前未连接，开始重连
    if (this.isEnabled) {
      const connectionType = AppStorage.get('connectionType') as ConnectionType
      if (connectionType === ConnectionType.None) {
        this.startReconnect()
      }
    }
  }

  /**
   * 设置是否启用自动重连
   */
  async setEnabled(enabled: boolean): Promise<void> {
    this.isEnabled = enabled
    await this.preferencesHelper.putBoolean(AUTO_RECONNECT_ENABLED_KEY, enabled)

    if (enabled) {
      const connectionType = AppStorage.get('connectionType') as ConnectionType
      if (connectionType === ConnectionType.None) {
        this.startReconnect()
      }
    } else {
      this.stopReconnect()
    }
  }

  /**
   * 获取启用状态
   */
  isReconnectEnabled(): boolean {
    return this.isEnabled
  }

  /**
   * 设置重连间隔
   */
  async setInterval(seconds: number): Promise<void> {
    this.intervalSeconds = seconds
    await this.preferencesHelper.putNumber(AUTO_RECONNECT_INTERVAL_KEY, seconds)

    // 如果正在重连，重启定时器
    if (this.isEnabled && this.reconnectTimerID !== -1) {
      this.stopReconnect()
      this.startReconnect()
    }
  }

  /**
   * 获取重连间隔
   */
  getInterval(): number {
    return this.intervalSeconds
  }

  /**
   * 开始重连
   */
  private startReconnect(): void {
    if (this.reconnectTimerID !== -1) {
      return // 已经在重连
    }

    const nearLinkDeviceName = AppStorage.get('nearLinkDeviceName') as string
    if (!nearLinkDeviceName) {
      console.info('AutoReconnectManager: No device name saved, skip reconnect')
      return
    }

    console.info('AutoReconnectManager: Starting auto reconnect, interval:', this.intervalSeconds)

    // 立即执行一次连接
    this.executeReconnect()

    // 设置定时器
    this.reconnectTimerID = setInterval(() => {
      const connectionType = AppStorage.get('connectionType') as ConnectionType
      if (connectionType === ConnectionType.None) {
        this.executeReconnect()
      } else {
        this.stopReconnect()
      }
    }, this.intervalSeconds * 1000)
  }

  /**
   * 执行一次重连
   */
  private executeReconnect(): void {
    const nearLinkDeviceName = AppStorage.get('nearLinkDeviceName') as string
    if (nearLinkDeviceName) {
      console.info('AutoReconnectManager: Executing reconnect to:', nearLinkDeviceName)
      this.nearLinkManager.startScan(nearLinkDeviceName, (devices) => {
        console.info('AutoReconnectManager: Scan result:', devices.length)
      })
    }
  }

  /**
   * 停止重连
   */
  private stopReconnect(): void {
    if (this.reconnectTimerID !== -1) {
      clearInterval(this.reconnectTimerID)
      this.reconnectTimerID = -1
      console.info('AutoReconnectManager: Stopped auto reconnect')
    }
  }
}
