/* SPDX-License-Identifier: GPL-2.0 */
/* LED Multicolor class interface
 * Copyright (C) 2019-20 Texas Instruments Incorporated - http://www.ti.com/
 */

#ifndef _LINUX_MULTICOLOR_LEDS_H_INCLUDED
#define _LINUX_MULTICOLOR_LEDS_H_INCLUDED

#include <linux/leds.h>
#include <dt-bindings/leds/common.h>

struct led_init_data {
	/* device fwnode handle */
	struct fwnode_handle *fwnode;
	/*
	 * default <color:function> tuple, for backward compatibility
	 * with in-driver hard-coded LED names used as a fallback when
	 * DT "label" property is absent; it should be set to NULL
	 * in new LED class drivers.
	 */
	const char *default_label;
	/*
	 * string to be used for devicename section of LED class device
	 * either for label based LED name composition path or for fwnode
	 * based when devname_mandatory is true
	 */
	const char *devicename;
	/*
	 * indicates if LED name should always comprise devicename section;
	 * only LEDs exposed by drivers of hot-pluggable devices should
	 * set it to true
	 */
	bool devname_mandatory;
};

struct mc_subled {
	unsigned int color_index;
	unsigned int brightness;
	unsigned int intensity;
	unsigned int channel;
};

struct led_classdev_mc {
	/* led class device */
	struct led_classdev led_cdev;
	unsigned int num_colors;

	struct mc_subled *subled_info;
};

static inline struct led_classdev_mc *lcdev_to_mccdev(
						struct led_classdev *led_cdev)
{
	return container_of(led_cdev, struct led_classdev_mc, led_cdev);
}

#if IS_ENABLED(CONFIG_LEDS_CLASS_MULTICOLOR)
/**
 * led_classdev_multicolor_register_ext - register a new object of led_classdev
 *				      class with support for multicolor LEDs
 * @parent: the multicolor LED to register
 * @mcled_cdev: the led_classdev_mc structure for this device
 * @init_data: the LED class multicolor device initialization data
 *
 * Returns: 0 on success or negative error value on failure
 */
int led_classdev_multicolor_register_ext(struct device *parent,
					    struct led_classdev_mc *mcled_cdev,
					    struct led_init_data *init_data);

static inline int led_classdev_multicolor_register(struct device *parent,
					    struct led_classdev_mc *mcled_cdev)
{
	return led_classdev_multicolor_register_ext(parent, mcled_cdev, NULL);
}

/**
 * led_classdev_multicolor_unregister - unregisters an object of led_classdev
 *					class with support for multicolor LEDs
 * @mcled_cdev: the multicolor LED to unregister
 *
 * Unregister a previously registered via led_classdev_multicolor_register
 * object
 */
void led_classdev_multicolor_unregister(struct led_classdev_mc *mcled_cdev);

/* Calculate brightness for the monochrome LED cluster */
int led_mc_calc_color_components(struct led_classdev_mc *mcled_cdev,
				 enum led_brightness brightness);

int devm_led_classdev_multicolor_register_ext(struct device *parent,
					  struct led_classdev_mc *mcled_cdev,
					  struct led_init_data *init_data);

static inline int devm_led_classdev_multicolor_register(struct device *parent,
				     struct led_classdev_mc *mcled_cdev)
{
	return devm_led_classdev_multicolor_register_ext(parent, mcled_cdev,
							 NULL);
}

void devm_led_classdev_multicolor_unregister(struct device *parent,
					    struct led_classdev_mc *mcled_cdev);
#else

static inline int led_classdev_multicolor_register_ext(struct device *parent,
					    struct led_classdev_mc *mcled_cdev,
					    struct led_init_data *init_data)
{
	return -EINVAL;
}

static inline int led_classdev_multicolor_register(struct device *parent,
					    struct led_classdev_mc *mcled_cdev)
{
	return led_classdev_multicolor_register_ext(parent, mcled_cdev, NULL);
}

static inline void led_classdev_multicolor_unregister(struct led_classdev_mc *mcled_cdev) {};
static inline int led_mc_calc_color_components(struct led_classdev_mc *mcled_cdev,
					       enum led_brightness brightness)
{
	return -EINVAL;
}

static inline int devm_led_classdev_multicolor_register_ext(struct device *parent,
					  struct led_classdev_mc *mcled_cdev,
					  struct led_init_data *init_data)
{
	return -EINVAL;
}

static inline int devm_led_classdev_multicolor_register(struct device *parent,
					     struct led_classdev_mc *mcled_cdev)
{
	return devm_led_classdev_multicolor_register_ext(parent, mcled_cdev,
							 NULL);
}

static inline void devm_led_classdev_multicolor_unregister(struct device *parent,
					    struct led_classdev_mc *mcled_cdev)
{};

#endif  /* IS_ENABLED(CONFIG_LEDS_CLASS_MULTICOLOR) */
#endif	/* _LINUX_MULTICOLOR_LEDS_H_INCLUDED */
