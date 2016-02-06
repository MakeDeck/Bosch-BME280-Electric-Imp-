class BME280 {
      static BME280_REGISTER_DIG_T1              = 0x88;
      static BME280_REGISTER_DIG_T2              = 0x8A;
      static BME280_REGISTER_DIG_T3              = 0x8C;

      static BME280_REGISTER_DIG_P1              = 0x8E;
      static BME280_REGISTER_DIG_P2              = 0x90;
      static BME280_REGISTER_DIG_P3              = 0x92;
      static BME280_REGISTER_DIG_P4              = 0x94;
      static BME280_REGISTER_DIG_P5              = 0x96;
      static BME280_REGISTER_DIG_P6              = 0x98;
      static BME280_REGISTER_DIG_P7              = 0x9A;
      static BME280_REGISTER_DIG_P8              = 0x9C;
      static BME280_REGISTER_DIG_P9              = 0x9E;

      static BME280_REGISTER_DIG_H1              = 0xA1;
      static BME280_REGISTER_DIG_H2              = 0xE1;
      static BME280_REGISTER_DIG_H3              = 0xE3;
      static BME280_REGISTER_DIG_H4              = 0xE4;
      static BME280_REGISTER_DIG_H5              = 0xE5;
      static BME280_REGISTER_DIG_H6              = 0xE7;

      static BME280_REGISTER_CHIPID             = 0xD0;
      static BME280_REGISTER_VERSION            = 0xD1;
      static BME280_REGISTER_SOFTRESET          = 0xE0;

      static BME280_REGISTER_CAL26              = 0xE1;  

      static BME280_REGISTER_CONTROLHUMID       = 0xF2;
      static BME280_REGISTER_CONTROL            = 0xF4;
      static BME280_REGISTER_CONFIG             = 0xF5;
      static BME280_REGISTER_PRESSUREDATA       = 0xF7;
      static BME280_REGISTER_TEMPDATA           = 0xFA;
      static BME280_REGISTER_HUMIDDATA          = 0xFD;

	  _i2c = null;
	  _addr = 0;

	  constructor(i2cbus, addr_8bit) {
		  _i2c = i2cbus;
		  _addr = addr_8bit << 1;
	  }

	  function init() {
  		local id = chipID();
  		if (id != 0x60) {
  			server.log(format("Invalid chip ID: 0x%02X", id));
  		} else {
  			server.log(format("BME280 chip ID: 0x%02X", id));
  			
  			_writeReg(BME280_REGISTER_CONTROLHUMID, 0x05); 
  			
  			_writeReg(BME280_REGISTER_CONTROL, 0xB7); 
  		}
	  }
	  function readTemp() {
	    local regData = _readReg(BME280_REGISTER_TEMPDATA, 3);
	    
	    foreach (index, value in regData) {
	      server.log(format("Index: %i, Value %i", index, value));
	    }
	    local value = regData[0];
	    value = value << 8;
	    value = value + regData[1];
	    value = value << 8;
	    value = value + regData[2];
	    local adc_T = value >> 4;
	    server.log("BME280 TEMP ADC RAW: " + adc_T);
	    local v_dig_T1 = _readReg(BME280_REGISTER_DIG_T1, 2);
	    local dig_T1 = v_dig_T1[0];
	    dig_T1 = (dig_T1 << 8) + v_dig_T1[1];
	    
	    local v_dig_T2 = _readReg(BME280_REGISTER_DIG_T2, 2);
	    local dig_T2 = v_dig_T2[0];
	    dig_T2 = (dig_T2 << 8) + v_dig_T2[1];
	    
	    local v_dig_T3 = _readReg(BME280_REGISTER_DIG_T3, 2);
	    local dig_T3 = v_dig_T3[0];
	    dig_T3 = (dig_T3 << 8) + v_dig_T3[1];
	    
	    local var1  = ((((adc_T>>3) - (dig_T1 <<1))) *
	   (dig_T2)) >> 11;

      local var2  = (((((adc_T>>4) - (dig_T1)) *
	     ((adc_T>>4) - (dig_T1))) >> 12) *
	   (dig_T3)) >> 14;

      local t_fine = var1 + var2;
	    local T = (t_fine * 5 + 128) >> 8;
	    server.log("BME280 TEMP COMPENSATED: " + T);
	  }

	  function chipID() {
  		local i2cByte;
  		i2cByte = _readReg(BME280_REGISTER_CHIPID, 1);
  		return i2cByte[0];
	  }

	  function _twosComp(value, mask) {
  		value = ~(value & mask) + 1;
  		return -1 * (value & mask);
	  }

	  function _readReg(reg, numBytes) {
  		local result = _i2c.read(_addr, reg.tochar(), numBytes);
  		if (result == null) {
  			throw "I2C read error: " + _i2c.readerror();
  		}
  		return result;
	  }

	  function _writeReg(reg, ...) {
  		local s = reg.tochar();
  		foreach (b in vargv) {
  			s += b.tochar();
  		}
  		local result = _i2c.write(_addr, s);
  		if (result) {
  			throw "I2C write error: " + result;
  		}
  		return result;
	  }

}



i2c <- hardware.i2cAB;
hardware.i2cAB.configure(CLOCK_SPEED_400_KHZ);

bme280 <- BME280(i2c, 0x76);
bme280.init();
bme280.readTemp();