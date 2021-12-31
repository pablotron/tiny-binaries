#![no_std]
#![no_main]

extern crate libc;

#[no_mangle]
pub extern "C" fn main(_argc: isize, _argv: *const *const u8) -> isize {
  const HI: &'static str = "hi!\n\0";

	unsafe {
		libc::printf(HI.as_ptr() as *const _);
	}

	0
}

#[panic_handler]
fn my_panic(_info: &core::panic::PanicInfo) -> ! {
	loop {}
}
