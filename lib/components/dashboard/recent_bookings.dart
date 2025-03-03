import 'package:flutter/material.dart';

class RecentBooking {
  final String guestName;
  final String roomNumber;
  final String checkIn;
  final String checkOut;
  final String status;
  final Color statusColor;

  RecentBooking({
    required this.guestName,
    required this.roomNumber,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    required this.statusColor,
  });
}

class RecentBookings extends StatelessWidget {
  RecentBookings({Key? key}) : super(key: key);

  // Sample data - replace with your actual data
  final List<RecentBooking> bookings = [
    RecentBooking(
      guestName: "James Wilson",
      roomNumber: "301",
      checkIn: "March 3, 2025",
      checkOut: "March 5, 2025",
      status: "Checked In",
      statusColor: Colors.green,
    ),
    RecentBooking(
      guestName: "Sarah Johnson",
      roomNumber: "205",
      checkIn: "March 4, 2025",
      checkOut: "March 7, 2025",
      status: "Reserved",
      statusColor: Colors.blue,
    ),
    RecentBooking(
      guestName: "Robert Brown",
      roomNumber: "418",
      checkIn: "March 5, 2025",
      checkOut: "March 8, 2025",
      status: "Reserved",
      statusColor: Colors.blue,
    ),
    RecentBooking(
      guestName: "Emily Davis",
      roomNumber: "112",
      checkIn: "March 3, 2025",
      checkOut: "March 4, 2025",
      status: "Checked Out",
      statusColor: Colors.grey,
    ),
    RecentBooking(
      guestName: "Michael Lee",
      roomNumber: "506",
      checkIn: "March 2, 2025",
      checkOut: "March 6, 2025",
      status: "Checked In",
      statusColor: Colors.green,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[800] 
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Bookings",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : Colors.grey[800],
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text("View All"),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bookings.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          booking.roomNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.guestName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "${booking.checkIn} - ${booking.checkOut}",
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.grey[400] 
                                  : Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: booking.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        booking.status,
                        style: TextStyle(
                          color: booking.statusColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
