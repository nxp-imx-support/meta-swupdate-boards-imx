function preinst()
	local out = "Pre installed script called"

	return true, out

end

function postinst()
	local out = "Post installed script called"

	print("enable emmc(/dev/mmcblk0) boot partition 1")

	local mmc_check = os.execute("which mmc > /dev/null 2>&1")
	if mmc_check ~= 0 and mmc_check ~= true then
		print("mmc command not found, skipping boot partition enable")
		return true, out
	end

	local ret = os.execute("mmc bootpart enable 1 1 /dev/mmcblk0")
	if ret == 0 or ret == true then
		print("Success")
		return true, out
	else
		print("Failed:", ret)
		return false, out
	end
end
