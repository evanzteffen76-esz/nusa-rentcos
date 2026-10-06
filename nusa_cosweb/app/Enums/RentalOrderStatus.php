<?php

namespace App\Enums;

enum RentalOrderStatus: string
{
    case Pending = 'pending';
    case Approved = 'approved';
    case Rejected = 'rejected';
    case Returned = 'returned';
    case Completed = 'completed';
}
