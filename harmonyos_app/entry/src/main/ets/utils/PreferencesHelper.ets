import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';

const PREFERENCES_NAME = 'app_preferences';

export class PreferencesHelper {
  private static instance: PreferencesHelper;
  private preference: preferences.Preferences | null = null;

  private constructor() {}

  static getInstance(): PreferencesHelper {
    if (!PreferencesHelper.instance) {
      PreferencesHelper.instance = new PreferencesHelper();
    }
    return PreferencesHelper.instance;
  }

  async init(context: Context): Promise<void> {
    try {
      this.preference = await preferences.getPreferences(context, {
        name: PREFERENCES_NAME
      });
    } catch (error) {
      const err = error as BusinessError;
      console.error('Failed to get preferences:', err.code, err.message);
    }
  }

  async putString(key: string, value: string): Promise<void> {
    if (!this.preference) {
      console.error('Preferences not initialized');
      return;
    }
    try {
      await this.preference.put(key, value);
      await this.preference.flush();
    } catch (error) {
      const err = error as BusinessError;
      console.error('Failed to put string:', err.code, err.message);
    }
  }

  async getString(key: string, defaultValue: string = ''): Promise<string> {
    if (!this.preference) {
      return defaultValue;
    }
    try {
      const value = await this.preference.get(key, defaultValue);
      return value as string;
    } catch (error) {
      const err = error as BusinessError;
      console.error('Failed to get string:', err.code, err.message);
      return defaultValue;
    }
  }

  async putBoolean(key: string, value: boolean): Promise<void> {
    if (!this.preference) {
      console.error('Preferences not initialized');
      return;
    }
    try {
      await this.preference.put(key, value);
      await this.preference.flush();
    } catch (error) {
      const err = error as BusinessError;
      console.error('Failed to put boolean:', err.code, err.message);
    }
  }

  async getBoolean(key: string, defaultValue: boolean = false): Promise<boolean> {
    if (!this.preference) {
      return defaultValue;
    }
    try {
      const value = await this.preference.get(key, defaultValue);
      return value as boolean;
    } catch (error) {
      const err = error as BusinessError;
      console.error('Failed to get boolean:', err.code, err.message);
      return defaultValue;
    }
  }

  async putNumber(key: string, value: number): Promise<void> {
    if (!this.preference) {
      console.error('Preferences not initialized');
      return;
    }
    try {
      await this.preference.put(key, value);
      await this.preference.flush();
    } catch (error) {
      const err = error as BusinessError;
      console.error('Failed to put number:', err.code, err.message);
    }
  }

  async getNumber(key: string, defaultValue: number = 0): Promise<number> {
    if (!this.preference) {
      return defaultValue;
    }
    try {
      const value = await this.preference.get(key, defaultValue);
      return value as number;
    } catch (error) {
      const err = error as BusinessError;
      console.error('Failed to get number:', err.code, err.message);
      return defaultValue;
    }
  }
}
