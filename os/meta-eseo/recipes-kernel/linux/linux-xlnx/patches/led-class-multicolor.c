// SPDX-License-Identifier: GPL-2.0
// LED Multicolor class interface
// Copyright (C) 2019-20 Texas Instruments Incorporated - http://www.ti.com/
// Author: Dan Murphy <dmurphy@ti.com>

#include <linux/device.h>
#include <linux/init.h>
#include <linux/led-class-multicolor.h>
#include <linux/module.h>
#include <linux/slab.h>
#include <linux/uaccess.h>
#include <linux/of.h>
#include <uapi/linux/uleds.h>

#include "leds.h"

extern struct class *leds_class;

const char * const led_colors[LED_COLOR_ID_MAX] = {
	[LED_COLOR_ID_WHITE] = "white",
	[LED_COLOR_ID_RED] = "red",
	[LED_COLOR_ID_GREEN] = "green",
	[LED_COLOR_ID_BLUE] = "blue",
	[LED_COLOR_ID_AMBER] = "amber",
	[LED_COLOR_ID_VIOLET] = "violet",
	[LED_COLOR_ID_YELLOW] = "yellow",
	[LED_COLOR_ID_IR] = "ir",
	[LED_COLOR_ID_MULTI] = "multicolor",
	[LED_COLOR_ID_RGB] = "rgb",
};
EXPORT_SYMBOL_GPL(led_colors);

struct led_properties {
	u32		color;
	bool		color_present;
	const char	*function;
	u32		func_enum;
	bool		func_enum_present;
	const char	*label;
};

int led_mc_calc_color_components(struct led_classdev_mc *mcled_cdev,
				 enum led_brightness brightness)
{
	struct led_classdev *led_cdev = &mcled_cdev->led_cdev;
	int i;

	for (i = 0; i < mcled_cdev->num_colors; i++)
		mcled_cdev->subled_info[i].brightness = brightness *
					mcled_cdev->subled_info[i].intensity /
					led_cdev->max_brightness;

	return 0;
}
EXPORT_SYMBOL_GPL(led_mc_calc_color_components);

static ssize_t multi_intensity_store(struct device *dev,
				struct device_attribute *intensity_attr,
				const char *buf, size_t size)
{
	struct led_classdev *led_cdev = dev_get_drvdata(dev);
	struct led_classdev_mc *mcled_cdev = lcdev_to_mccdev(led_cdev);
	int nrchars, offset = 0;
	int intensity_value[LED_COLOR_ID_MAX];
	int i;
	ssize_t ret;

	mutex_lock(&led_cdev->led_access);

	for (i = 0; i < mcled_cdev->num_colors; i++) {
		ret = sscanf(buf + offset, "%i%n",
			     &intensity_value[i], &nrchars);
		if (ret != 1) {
			ret = -EINVAL;
			goto err_out;
		}
		offset += nrchars;
	}

	offset++;
	if (offset < size) {
		ret = -EINVAL;
		goto err_out;
	}

	for (i = 0; i < mcled_cdev->num_colors; i++)
		mcled_cdev->subled_info[i].intensity = intensity_value[i];

	led_set_brightness(led_cdev, led_cdev->brightness);
	ret = size;
err_out:
	mutex_unlock(&led_cdev->led_access);
	return ret;
}

static ssize_t multi_intensity_show(struct device *dev,
			      struct device_attribute *intensity_attr,
			      char *buf)
{
	struct led_classdev *led_cdev = dev_get_drvdata(dev);
	struct led_classdev_mc *mcled_cdev = lcdev_to_mccdev(led_cdev);
	int len = 0;
	int i;

	for (i = 0; i < mcled_cdev->num_colors; i++) {
		len += sprintf(buf + len, "%d",
			       mcled_cdev->subled_info[i].intensity);
		if (i < mcled_cdev->num_colors - 1)
			len += sprintf(buf + len, " ");
	}

	buf[len++] = '\n';
	return len;
}
static DEVICE_ATTR_RW(multi_intensity);

static ssize_t multi_index_show(struct device *dev,
			      struct device_attribute *multi_index_attr,
			      char *buf)
{
	struct led_classdev *led_cdev = dev_get_drvdata(dev);
	struct led_classdev_mc *mcled_cdev = lcdev_to_mccdev(led_cdev);
	int len = 0;
	int index;
	int i;

	for (i = 0; i < mcled_cdev->num_colors; i++) {
		index = mcled_cdev->subled_info[i].color_index;
		len += sprintf(buf + len, "%s", led_colors[index]);
		if (i < mcled_cdev->num_colors - 1)
			len += sprintf(buf + len, " ");
	}

	buf[len++] = '\n';
	return len;
}
static DEVICE_ATTR_RO(multi_index);

static struct attribute *led_multicolor_attrs[] = {
	&dev_attr_multi_intensity.attr,
	&dev_attr_multi_index.attr,
	NULL,
};
ATTRIBUTE_GROUPS(led_multicolor);

static void led_parse_fwnode_props(struct device *dev,
				   struct fwnode_handle *fwnode,
				   struct led_properties *props)
{
	int ret;

	if (!fwnode)
		return;

	if (fwnode_property_present(fwnode, "label")) {
		ret = fwnode_property_read_string(fwnode, "label", &props->label);
		if (ret)
			dev_err(dev, "Error parsing 'label' property (%d)\n", ret);
		return;
	}

	if (fwnode_property_present(fwnode, "color")) {
		ret = fwnode_property_read_u32(fwnode, "color", &props->color);
		if (ret)
			dev_err(dev, "Error parsing 'color' property (%d)\n", ret);
		else if (props->color >= LED_COLOR_ID_MAX)
			dev_err(dev, "LED color identifier out of range\n");
		else
			props->color_present = true;
	}


	if (!fwnode_property_present(fwnode, "function"))
		return;

	ret = fwnode_property_read_string(fwnode, "function", &props->function);
	if (ret) {
		dev_err(dev,
			"Error parsing 'function' property (%d)\n",
			ret);
	}

	if (!fwnode_property_present(fwnode, "function-enumerator"))
		return;

	ret = fwnode_property_read_u32(fwnode, "function-enumerator",
				       &props->func_enum);
	if (ret) {
		dev_err(dev,
			"Error parsing 'function-enumerator' property (%d)\n",
			ret);
	} else {
		props->func_enum_present = true;
	}
}

int led_compose_name(struct device *dev, struct led_init_data *init_data,
		     char *led_classdev_name)
{
	struct led_properties props = {};
	struct fwnode_handle *fwnode = init_data->fwnode;
	const char *devicename = init_data->devicename;

	/* We want to label LEDs that can produce full range of colors
	 * as RGB, not multicolor */
	BUG_ON(props.color == LED_COLOR_ID_MULTI);

	if (!led_classdev_name)
		return -EINVAL;

	led_parse_fwnode_props(dev, fwnode, &props);

	if (props.label) {
		/*
		 * If init_data.devicename is NULL, then it indicates that
		 * DT label should be used as-is for LED class device name.
		 * Otherwise the label is prepended with devicename to compose
		 * the final LED class device name.
		 */
		if (!devicename) {
			strscpy(led_classdev_name, props.label,
				LED_MAX_NAME_SIZE);
		} else {
			snprintf(led_classdev_name, LED_MAX_NAME_SIZE, "%s:%s",
				 devicename, props.label);
		}
	} else if (props.function || props.color_present) {
		char tmp_buf[LED_MAX_NAME_SIZE];

		if (props.func_enum_present) {
			snprintf(tmp_buf, LED_MAX_NAME_SIZE, "%s:%s-%d",
				 props.color_present ? led_colors[props.color] : "",
				 props.function ?: "", props.func_enum);
		} else {
			snprintf(tmp_buf, LED_MAX_NAME_SIZE, "%s:%s",
				 props.color_present ? led_colors[props.color] : "",
				 props.function ?: "");
		}
		if (init_data->devname_mandatory) {
			snprintf(led_classdev_name, LED_MAX_NAME_SIZE, "%s:%s",
				 devicename, tmp_buf);
		} else {
			strscpy(led_classdev_name, tmp_buf, LED_MAX_NAME_SIZE);

		}
	} else if (init_data->default_label) {
		if (!devicename) {
			dev_err(dev, "Legacy LED naming requires devicename segment");
			return -EINVAL;
		}
		snprintf(led_classdev_name, LED_MAX_NAME_SIZE, "%s:%s",
			 devicename, init_data->default_label);
	} else if (is_of_node(fwnode)) {
		strscpy(led_classdev_name, to_of_node(fwnode)->name,
			LED_MAX_NAME_SIZE);
	} else
		return -EINVAL;

	return 0;
}
EXPORT_SYMBOL_GPL(led_compose_name);

static int device_match_name(struct device *dev, const void *name)
{
	return sysfs_streq(dev_name(dev), name);
}

static inline struct device *class_find_device_by_name(struct class *class,
						       const char *name)
{
	return class_find_device(class, NULL, name, device_match_name);
}

static int led_classdev_next_name(const char *init_name, char *name,
				  size_t len)
{
	unsigned int i = 0;
	int ret = 0;
	struct device *dev;

	strlcpy(name, init_name, len);

	while ((ret < len) &&
	       (dev = class_find_device_by_name(leds_class, name))) {
		put_device(dev);
		ret = snprintf(name, len, "%s_%u", init_name, ++i);
	}

	if (ret >= len)
		return -ENOMEM;

	return i;
}

#ifdef CONFIG_LEDS_BRIGHTNESS_HW_CHANGED
static ssize_t brightness_hw_changed_show(struct device *dev,
		struct device_attribute *attr, char *buf)
{
	struct led_classdev *led_cdev = dev_get_drvdata(dev);

	if (led_cdev->brightness_hw_changed == -1)
		return -ENODATA;

	return sprintf(buf, "%u\n", led_cdev->brightness_hw_changed);
}

static DEVICE_ATTR_RO(brightness_hw_changed);

static int led_add_brightness_hw_changed(struct led_classdev *led_cdev)
{
	struct device *dev = led_cdev->dev;
	int ret;

	ret = device_create_file(dev, &dev_attr_brightness_hw_changed);
	if (ret) {
		dev_err(dev, "Error creating brightness_hw_changed\n");
		return ret;
	}

	led_cdev->brightness_hw_changed_kn =
		sysfs_get_dirent(dev->kobj.sd, "brightness_hw_changed");
	if (!led_cdev->brightness_hw_changed_kn) {
		dev_err(dev, "Error getting brightness_hw_changed kn\n");
		device_remove_file(dev, &dev_attr_brightness_hw_changed);
		return -ENXIO;
	}

	return 0;
}

static void led_remove_brightness_hw_changed(struct led_classdev *led_cdev)
{
	sysfs_put(led_cdev->brightness_hw_changed_kn);
	device_remove_file(led_cdev->dev, &dev_attr_brightness_hw_changed);
}

void led_classdev_notify_brightness_hw_changed(struct led_classdev *led_cdev,
					       enum led_brightness brightness)
{
	if (WARN_ON(!led_cdev->brightness_hw_changed_kn))
		return;

	led_cdev->brightness_hw_changed = brightness;
	sysfs_notify_dirent(led_cdev->brightness_hw_changed_kn);
}
EXPORT_SYMBOL_GPL(led_classdev_notify_brightness_hw_changed);
#else
static int led_add_brightness_hw_changed(struct led_classdev *led_cdev)
{
	return 0;
}
static void led_remove_brightness_hw_changed(struct led_classdev *led_cdev)
{
}
#endif

int led_classdev_register_ext(struct device *parent,
			      struct led_classdev *led_cdev,
			      struct led_init_data *init_data)
{
	char composed_name[LED_MAX_NAME_SIZE];
	char final_name[LED_MAX_NAME_SIZE];
	const char *proposed_name = composed_name;
	int ret;

	if (init_data) {
		if (init_data->devname_mandatory && !init_data->devicename) {
			dev_err(parent, "Mandatory device name is missing");
			return -EINVAL;
		}
		ret = led_compose_name(parent, init_data, composed_name);
		if (ret < 0)
			return ret;
	} else {
		proposed_name = led_cdev->name;
	}

	ret = led_classdev_next_name(proposed_name, final_name, sizeof(final_name));
	if (ret < 0)
		return ret;

	mutex_init(&led_cdev->led_access);
	mutex_lock(&led_cdev->led_access);
	led_cdev->dev = device_create_with_groups(leds_class, parent, 0,
				led_cdev, led_cdev->groups, "%s", final_name);
	if (IS_ERR(led_cdev->dev)) {
		mutex_unlock(&led_cdev->led_access);
		return PTR_ERR(led_cdev->dev);
	}
	if (init_data && init_data->fwnode)
		led_cdev->dev->fwnode = init_data->fwnode;

	if (ret)
		dev_warn(parent, "Led %s renamed to %s due to name collision",
				led_cdev->name, dev_name(led_cdev->dev));

	if (led_cdev->flags & LED_BRIGHT_HW_CHANGED) {
		ret = led_add_brightness_hw_changed(led_cdev);
		if (ret) {
			device_unregister(led_cdev->dev);
			led_cdev->dev = NULL;
			mutex_unlock(&led_cdev->led_access);
			return ret;
		}
	}

	led_cdev->work_flags = 0;
#ifdef CONFIG_LEDS_TRIGGERS
	init_rwsem(&led_cdev->trigger_lock);
#endif
#ifdef CONFIG_LEDS_BRIGHTNESS_HW_CHANGED
	led_cdev->brightness_hw_changed = -1;
#endif
	/* add to the list of leds */
	down_write(&leds_list_lock);
	list_add_tail(&led_cdev->node, &leds_list);
	up_write(&leds_list_lock);

	if (!led_cdev->max_brightness)
		led_cdev->max_brightness = LED_FULL;

	led_update_brightness(led_cdev);

	led_init_core(led_cdev);

#ifdef CONFIG_LEDS_TRIGGERS
	led_trigger_set_default(led_cdev);
#endif

	mutex_unlock(&led_cdev->led_access);

	dev_dbg(parent, "Registered led device: %s\n",
			led_cdev->name);

	return 0;
}
EXPORT_SYMBOL_GPL(led_classdev_register_ext);

int led_classdev_multicolor_register_ext(struct device *parent,
				     struct led_classdev_mc *mcled_cdev,
				     struct led_init_data *init_data)
{
	struct led_classdev *led_cdev;

	if (!mcled_cdev)
		return -EINVAL;

	if (mcled_cdev->num_colors <= 0)
		return -EINVAL;

	if (mcled_cdev->num_colors > LED_COLOR_ID_MAX)
		return -EINVAL;

	led_cdev = &mcled_cdev->led_cdev;
	mcled_cdev->led_cdev.groups = led_multicolor_groups;

	return led_classdev_register_ext(parent, led_cdev, init_data);
}
EXPORT_SYMBOL_GPL(led_classdev_multicolor_register_ext);

void led_classdev_multicolor_unregister(struct led_classdev_mc *mcled_cdev)
{
	if (!mcled_cdev)
		return;

	led_classdev_unregister(&mcled_cdev->led_cdev);
}
EXPORT_SYMBOL_GPL(led_classdev_multicolor_unregister);

static void devm_led_classdev_multicolor_release(struct device *dev, void *res)
{
	led_classdev_multicolor_unregister(*(struct led_classdev_mc **)res);
}

int devm_led_classdev_multicolor_register_ext(struct device *parent,
					     struct led_classdev_mc *mcled_cdev,
					     struct led_init_data *init_data)
{
	struct led_classdev_mc **dr;
	int ret;

	dr = devres_alloc(devm_led_classdev_multicolor_release,
			  sizeof(*dr), GFP_KERNEL);
	if (!dr)
		return -ENOMEM;

	ret = led_classdev_multicolor_register_ext(parent, mcled_cdev,
						   init_data);
	if (ret) {
		devres_free(dr);
		return ret;
	}

	*dr = mcled_cdev;
	devres_add(parent, dr);

	return 0;
}
EXPORT_SYMBOL_GPL(devm_led_classdev_multicolor_register_ext);

static int devm_led_classdev_multicolor_match(struct device *dev,
					      void *res, void *data)
{
	struct led_classdev_mc **p = res;

	if (WARN_ON(!p || !*p))
		return 0;

	return *p == data;
}

void devm_led_classdev_multicolor_unregister(struct device *dev,
					     struct led_classdev_mc *mcled_cdev)
{
	WARN_ON(devres_release(dev,
			       devm_led_classdev_multicolor_release,
			       devm_led_classdev_multicolor_match, mcled_cdev));
}
EXPORT_SYMBOL_GPL(devm_led_classdev_multicolor_unregister);

MODULE_AUTHOR("Dan Murphy <dmurphy@ti.com>");
MODULE_DESCRIPTION("Multicolor LED class interface");
MODULE_LICENSE("GPL v2");
