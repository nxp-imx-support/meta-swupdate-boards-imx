-- Bootloader is written to the eMMC boot0 hardware partition.
-- boot0 is read-only by default; unlock it before images are installed.
local BOOTPART = "mmcblk0boot0"

function preinst()
	local out = "Pre installed script called"
	local ok = os.execute("echo 0 > /sys/block/" .. BOOTPART .. "/force_ro")
	if ok ~= 0 and ok ~= true then
		return false, "Failed to unlock /dev/" .. BOOTPART
	end
	return true, out
end

function postinst()
	local out = "Post installed script called"

	-- Re-lock boot0 regardless of the outcome below.
	os.execute("echo 1 > /sys/block/" .. BOOTPART .. "/force_ro")

	local mmc_check = os.execute("command -v mmc > /dev/null 2>&1")
	if mmc_check ~= 0 and mmc_check ~= true then
		print("mmc command not found, skipping boot partition enable")
		return true, out
	end

	print("enable emmc(/dev/mmcblk0) boot partition 1")
	local ret = os.execute("mmc bootpart enable 1 1 /dev/mmcblk0")
	if ret == 0 or ret == true then
		print("Success")
		return true, out
	else
		print("Failed:", ret)
		return false, out
	end
end
