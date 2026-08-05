function preinst()
	local out = "Pre installed script called"

	return true, out

end

function postinst()
	local out = "Post installed script called"

	print("enable emmc(/dev/mmcblk0) boot partition 1")

	local ret = os.execute("mmc bootpart enable 1 1 /dev/mmcblk0")
	if ret == 0 or ret == true then
		print("Success")
	else
		-- mmc-utils may not be present or boot partition already enabled;
		-- treat as non-fatal warning so the upgrade can complete.
		print("Warning: mmc bootpart enable returned non-zero - continuing anyway")
	end

	return true, out
end
